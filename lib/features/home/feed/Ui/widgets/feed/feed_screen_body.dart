import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/lottie_loader.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_item.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_state.dart';

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
                  child: Center(child: LottieLoader()),
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



