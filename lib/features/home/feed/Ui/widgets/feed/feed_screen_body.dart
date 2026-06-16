import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/widgets/shimmer_loading.dart';
import 'package:riff/features/commercial/data/models/ad.dart';
import 'package:riff/features/commercial/data/repos/ad_repo.dart';
import 'package:riff/features/commercial/ui/widgets/ad_card.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/lottie_loader.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_item.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/feed_empty_state.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fade + slide-up entrance animation for list items with staggered delay
// ─────────────────────────────────────────────────────────────────────────────
class _FadeSlideIn extends StatefulWidget {
  final int index;
  final Widget child;
  const _FadeSlideIn({required this.index, required this.child});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    // Cap stagger at ~300 ms so late items don't wait too long
    final stagger = Duration(
      milliseconds: (widget.index * 55).clamp(0, 280),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(stagger, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class FeedScreenBody extends StatefulWidget {
  const FeedScreenBody({super.key});

  @override
  State<FeedScreenBody> createState() => _FeedScreenBodyState();
}

class _FeedScreenBodyState extends State<FeedScreenBody> {
  late final ScrollController _controller;
  final AdRepo _adRepo = getIt<AdRepo>();
  List<Ad> _ads = [];

  /// Insert one ad every [_adEvery] posts.
  static const int _adEvery = 3;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_onScroll);
    _loadAds();
  }

  Future<void> _loadAds() async {
    final result = await _adRepo.getFeedAds(limit: 10);
    result.when(
      success: (ads) {
        if (mounted) setState(() => _ads = ads);
      },
      failure: (err) => debugPrint('⚠️ Ad load failed: ${err.errors?.first.message}'),
    );
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
    const threshold = 0.7;
    if (current / maxScroll > threshold) {
      final cubit = context.read<FeedCubit>();
      if (cubit.hasMore && !cubit.isLoadingMore) {
        cubit.getPosts();
      }
    }
  }

  /// Build the mixed list inserting one ad every [_adEvery] posts.
  /// Always inserts at least one ad at position [_adEvery] (or end of list).
  List<dynamic> _buildMixedList(List<dynamic> posts) {
    if (_ads.isEmpty) return posts;
    final mixed = <dynamic>[];
    int adIndex = 0;
    for (int i = 0; i < posts.length; i++) {
      mixed.add(posts[i]);
      final shouldInsert = (i + 1) % _adEvery == 0;
      if (shouldInsert && adIndex < _ads.length) {
        mixed.add(_ads[adIndex % _ads.length]);
        adIndex++;
      }
    }
    // If no ad was inserted yet (fewer posts than _adEvery), append one at the end
    if (adIndex == 0 && _ads.isNotEmpty) {
      mixed.add(_ads[0]);
    }
    return mixed;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FeedCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      backgroundColor: isDark ? const Color(0xFF252525) : ColorManager.white,
      color: isDark ? const Color(0xFFC6FF00) : ColorManager.primaryBlack,
      onRefresh: () async {
        await cubit.getPosts(refresh: true);
        await _loadAds();
      },
      child: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text("No posts loaded")),
            loading: () => const FeedShimmer(),
            success: (postsResponse) {
              final posts = postsResponse.data;

              if (posts.isEmpty) {
                return const FeedEmptyState();
              }

              final isLoadingMore = cubit.isLoadingMore;
              final paginationError = cubit.lastError;
              final mixed = _buildMixedList(posts);
              final extra = (isLoadingMore || paginationError != null) ? 1 : 0;

              return ListView.builder(
                controller: _controller,
                padding: const EdgeInsets.all(16),
                itemCount: mixed.length + extra,
                itemBuilder: (context, index) {
                  if (index < mixed.length) {
                    final item = mixed[index];
                    if (item is Ad) {
                      return _FadeSlideIn(
                        index: index,
                        child: AdCard(ad: item, adRepo: _adRepo),
                      );
                    }
                    return _FadeSlideIn(
                      index: index,
                      child: PostItem(post: item),
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
                              paginationError.errors?.first.message ??
                                  'Failed to load more posts',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: cubit.retryLoadMore,
                              icon: Icon(Icons.refresh,
                                  color: ColorManager.primaryBlack),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: LottieLoader()),
                  );
                },
              );
            },
            failure: (error) {
              return Center(
                  child:
                      Text(error.errors?[0].message ?? "An error occurred"));
            },
          );
        },
      ),
    );
  }
}
