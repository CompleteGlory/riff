import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/widgets/shimmer_loading.dart';
import 'package:riff/features/commercial/data/models/ad.dart';
import 'package:riff/features/commercial/data/repos/ad_repo.dart';
import 'package:riff/features/commercial/ui/widgets/ad_card.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/lottie_loader.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_item.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/feed_empty_state.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/trending_post_card.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_cubit.dart';
import 'package:riff/features/home/feed/logic/feed_list_builder.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_state.dart';
import 'package:riff/generated/l10n.dart';
import 'package:riff/core/widgets/app_error_widget.dart';
import 'package:riff/core/widgets/offline_banner.dart';

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
  // Use the shared controller from HomeCubit so re-tapping the feed tab
  // can animate to top via HomeCubit.changeScreen without needing a new
  // freezed state variant.
  late final ScrollController _controller;
  final AdRepo _adRepo = getIt<AdRepo>();
  List<Ad> _ads = [];

  /// Insert one ad every [_adEvery] posts.
  static const int _adEvery = 3;

  // Placeholder for the trending card in the mixed list — see feed_list_builder.
  static const _trendingSlot = trendingSlot;

  @override
  void initState() {
    super.initState();
    // Borrow HomeCubit's shared scroll controller so HomeCubit can
    // animate to top when the feed tab is re-tapped.
    _controller = context.read<HomeCubit>().feedScrollController;
    _controller.addListener(_onScroll);
    _loadAds();
    // Load trending post after first frame so FeedCubit is available in context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FeedCubit>().loadTrending();
    });
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
    // Don't dispose — HomeCubit owns and disposes this controller.
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

  /// Ordering rules live in [buildFeedItems] so they can be unit-tested
  /// without booting the feed.
  List<dynamic> _buildMixedList(List<dynamic> posts, Post? trending) =>
      buildFeedItems(
        posts: posts,
        trending: trending,
        ads: _ads,
        adEvery: _adEvery,
      );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FeedCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      backgroundColor: isDark ? const Color(0xFF252525) : ColorManager.white,
      color: isDark ? const Color(0xFFC6FF00) : ColorManager.primaryBlack,
      onRefresh: () async {
        await Future.wait([
          cubit.getPosts(refresh: true),
          cubit.loadTrending(),
          _loadAds(),
        ]);
      },
      child: BlocBuilder<FeedCubit, FeedState>(
        builder: (context, state) {
          return state.when(
            initial: () => Center(child: Text(S.of(context).noPostsLoaded)),
            loading: () => const FeedShimmer(),
            success: (postsResponse) {
              final posts = postsResponse.data;

              if (posts.isEmpty) {
                return const FeedEmptyState();
              }

              final isLoadingMore = cubit.isLoadingMore;
              final paginationError = cubit.lastError;
              final trending = cubit.trendingPost;
              final mixed = _buildMixedList(posts, trending);
              final extra = (isLoadingMore || paginationError != null) ? 1 : 0;

              final list = ListView.builder(
                controller: _controller,
                padding: const EdgeInsets.all(16),
                itemCount: mixed.length + extra,
                itemBuilder: (context, index) {
                  if (index < mixed.length) {
                    final item = mixed[index];
                    if (identical(item, _trendingSlot)) {
                      return _FadeSlideIn(
                        index: index,
                        child: TrendingPostCard(post: trending!),
                      );
                    }
                    if (item is Ad) {
                      return _FadeSlideIn(
                        index: index,
                        child: AdCard(ad: item, adRepo: _adRepo),
                      );
                    }
                    return _FadeSlideIn(
                      index: index,
                      child: PostItem(post: item as Post),
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
                                  S.of(context).failedToLoadMorePosts,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: cubit.retryLoadMore,
                              icon: Icon(Icons.refresh,
                                  color: ColorManager.primaryBlack),
                              label: Text(S.of(context).retryBtn),
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

              if (!cubit.isShowingCached) return list;
              // The global banner says the device is offline; this says which
              // list is a snapshot.
              return Column(children: [
                OfflineCachedNotice(savedAt: cubit.cacheSavedAt),
                Expanded(child: list),
              ]);
            },
            failure: (error) {
              // Wrap in a scrollable so the parent RefreshIndicator
              // can detect the pull-to-refresh gesture.
              final msg = error.errors?.first.message ?? error.message;
              // The failure carries whether it was a transport failure, so this
              // no longer has to guess from the wording of an English string —
              // which was always fragile and simply never matched in Arabic.
              final isConnErr = error.isOffline;
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: isConnErr
                        ? OfflineEmptyState(
                            onRetry: () => cubit.getPosts(refresh: true),
                          )
                        : AppErrorWidget(
                            message: msg,
                            isConnectionError: false,
                            onRetry: () => cubit.getPosts(refresh: true),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

