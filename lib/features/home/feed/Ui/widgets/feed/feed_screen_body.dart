import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/shimmer_loading.dart';
import 'package:riff/features/commercial/data/models/ad.dart';
import 'package:riff/features/commercial/data/repos/ad_repo.dart';
import 'package:riff/features/commercial/ui/widgets/ad_card.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/lottie_loader.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_item.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/feed_empty_state.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/trending_post_card.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_state.dart';
import 'package:riff/generated/l10n.dart';

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

  // Sentinel object used as a placeholder for the trending card in the list
  static const _trendingSlot = Object();

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
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

  /// Build the mixed list inserting:
  /// - trending card after the 2nd post (index 2)
  /// - one ad every [_adEvery] posts
  List<dynamic> _buildMixedList(List<dynamic> posts, Post? trending) {
    final mixed = <dynamic>[];
    int adIndex = 0;
    for (int i = 0; i < posts.length; i++) {
      mixed.add(posts[i]);

      // Insert trending after position 1 (after the 2nd post)
      if (i == 1 && trending != null) {
        mixed.add(_trendingSlot);
      }

      if (_ads.isNotEmpty) {
        final shouldInsert = (i + 1) % _adEvery == 0;
        if (shouldInsert && adIndex < _ads.length) {
          mixed.add(_ads[adIndex % _ads.length]);
          adIndex++;
        }
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

              return ListView.builder(
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
            },
            failure: (error) {
              // Wrap in a scrollable so the parent RefreshIndicator
              // can detect the pull-to-refresh gesture.
              final msg = error.errors?.first.message;
              final isConnErr = msg != null &&
                  (msg.toLowerCase().contains('connect') ||
                      msg.toLowerCase().contains('network') ||
                      msg.toLowerCase().contains('socket') ||
                      msg.toLowerCase().contains('timeout'));
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _FeedErrorWidget(
                      message: msg ?? S.of(context).somethingWentWrong,
                      isConnectionError: isConnErr,
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

// ─────────────────────────────────────────────────────────────────────────────
// Feed error state — animated icon + message + retry button.
// Must be inside a scrollable parent so the RefreshIndicator above it can
// detect pull-to-refresh even when the list is empty.
// ─────────────────────────────────────────────────────────────────────────────

class _FeedErrorWidget extends StatefulWidget {
  final String message;
  final bool isConnectionError;
  final VoidCallback onRetry;

  const _FeedErrorWidget({
    required this.message,
    required this.isConnectionError,
    required this.onRetry,
  });

  @override
  State<_FeedErrorWidget> createState() => _FeedErrorWidgetState();
}

class _FeedErrorWidgetState extends State<_FeedErrorWidget>
    with TickerProviderStateMixin {
  // Gentle floating bob
  late final AnimationController _bobController;
  late final Animation<double> _bob;

  // Rotation pulse on the icon ring
  late final AnimationController _rotateController;
  late final Animation<double> _rotate;

  // Fade-in entrance
  late final AnimationController _fadeController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _bob = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _rotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _bobController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFFC6FF00) : ColorManager.primaryBlack;
    final subtleColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF0F0F0);
    final iconBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Animated icon ──────────────────────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge([_bob, _rotate]),
                  builder: (_, __) {
                    return Transform.translate(
                      offset: Offset(0, _bob.value),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Slowly rotating dashed ring
                          Transform.rotate(
                            angle: _rotate.value,
                            child: CustomPaint(
                              size: Size(96.r, 96.r),
                              painter: _DashedCirclePainter(
                                color: subtleColor,
                                dashCount: 12,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          // Icon container
                          Container(
                            width: 72.r,
                            height: 72.r,
                            decoration: BoxDecoration(
                              color: iconBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isConnectionError
                                  ? Icons.wifi_off_rounded
                                  : Icons.cloud_off_rounded,
                              size: 32.r,
                              color: isDark
                                  ? const Color(0xFF888888)
                                  : const Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 28.h),

                // ── Title ──────────────────────────────────────────────────
                Text(
                  widget.isConnectionError ? S.of(context).noConnection : S.of(context).serverError,
                  style: TextStyles.font18Semibold,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                // ── Subtitle ───────────────────────────────────────────────
                Text(
                  widget.isConnectionError
                      ? S.of(context).checkYourConnection
                      : S.of(context).somethingWentWrong,
                  style: TextStyles.font14Medium.copyWith(
                    color: isDark
                        ? const Color(0xFF888888)
                        : const Color(0xFF999999),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32.h),

                // ── Retry button ───────────────────────────────────────────
                GestureDetector(
                  onTap: widget.onRetry,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 28.w, vertical: 13.h),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 18.r,
                          color: isDark
                              ? ColorManager.primaryBlack
                              : ColorManager.white,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          S.of(context).tryAgainBtn,
                          style: TextStyles.font14Medium.copyWith(
                            color: isDark
                                ? ColorManager.primaryBlack
                                : ColorManager.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // ── Pull-down hint ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16.r,
                      color: isDark
                          ? const Color(0xFF555555)
                          : const Color(0xFFCCCCCC),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'or pull down to refresh',
                      style: TextStyles.font12Medium.copyWith(
                        color: isDark
                            ? const Color(0xFF555555)
                            : const Color(0xFFCCCCCC),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Custom painter for the dashed rotating ring ───────────────────────────────

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;

  const _DashedCirclePainter({
    required this.color,
    required this.dashCount,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;
    final angleStep = (2 * math.pi) / dashCount;
    const dashAngle = 0.18; // radians each dash spans

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * angleStep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.color != color || old.dashCount != dashCount;
}
