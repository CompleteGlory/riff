import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/features/home/feed/Ui/widgets/post_item.dart';
import 'package:riff/features/home/feed/logic/cubit/feed_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/feed_state.dart';

class FeedScreenBody extends StatefulWidget {
  const FeedScreenBody({super.key});

  @override
  State<FeedScreenBody> createState() => _FeedScreenBodyState();
}

class _FeedScreenBodyState extends State<FeedScreenBody> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final maxScroll = _controller.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final current = _controller.position.pixels;
    final threshold = 0.7;
    if (current / maxScroll > threshold) {
      final cubit = context.read<FeedCubit>();
      if (cubit.hasMore && !cubit.isLoadingMore) {
        cubit.getPosts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FeedCubit>();

    return RefreshIndicator(
      backgroundColor: ColorManager.white,
      color: ColorManager.primaryBlack,
      onRefresh: () => cubit.getPosts(refresh: true),
      child: BlocBuilder<FeedCubit, FeedState>(
      builder: (context, state) {
        return state.when(
          initial: () => const Center(child: Text("No posts loaded")),
          loading: () => Center(child: CircularProgressIndicator(color: ColorManager.primaryBlack,)),
          success: (postsResponse) {
            final posts = postsResponse.data;

            if (posts.isEmpty) {
              return const Center(child: Text("No posts yet"));
            }

            final isLoadingMore = cubit.isLoadingMore;
            final paginationError = cubit.lastError;

            return ListView.builder(
              controller: _controller,
              padding: const EdgeInsets.all(16),
              itemCount: posts.length + (isLoadingMore || paginationError != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < posts.length) {
                  final post = posts[index];
                  return PostItem(
                    post: post,
                  );
                }

                if (paginationError != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            paginationError.errors?.first.message ?? 'Failed to load more posts',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: cubit.retryLoadMore,
                            icon:  Icon(Icons.refresh,color: ColorManager.primaryBlack,),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // bottom loader with Lottie
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: _LottieLoader()),
                );
              },
            );
          },
          failure: (error) {
            return Center(child: Text(error.errors?[0].message??"An error occurred"));
          },
        );
      },
    )
    );
  }
}

class _LottieLoader extends StatelessWidget {
  const _LottieLoader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Center(
        child: Lottie.asset(
          'assets/animations/loading.json',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
          animate: true,
        ),
      ),
    );
  }
}

// Fallback animation (used if Lottie asset is not available)
class _LoadingMore extends StatefulWidget {
  const _LoadingMore();

  @override
  State<_LoadingMore> createState() => _LoadingMoreState();
}

class _LoadingMoreState extends State<_LoadingMore> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900),)..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(

      height: 56,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _anim, curve: const Interval(0.0, 0.33, curve: Curves.easeInOut))),
              child: const _Dot(),
            ),
            const SizedBox(width: 8),
            ScaleTransition(
              scale: Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _anim, curve: const Interval(0.33, 0.66, curve: Curves.easeInOut))),
              child: const _Dot(),
            ),
            const SizedBox(width: 8),
            ScaleTransition(
              scale: Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _anim, curve: const Interval(0.66, 1.0, curve: Curves.easeInOut))),
              child: const _Dot(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: ColorManager.primaryBlack,
        shape: BoxShape.circle,
      ),
    );
  }
}
