// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';
import 'package:riff/features/home/feed/Ui/widgets/comments/comment_sheet.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_header.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_content.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_actions.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/shared_post_card.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/share_sheet.dart';
import 'package:riff/features/home/feed/Ui/post_detail_screen.dart';
import 'package:riff/core/routing/animated_page_route.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/lottie_loader.dart';
import 'package:riff/features/home/reels/ui/reels_screen.dart';
import 'package:riff/features/home/feed/logic/cubit/posts/post_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/comments/comment_cubit.dart';
import 'package:riff/features/home/feed/logic/view_tracker.dart';
import 'package:riff/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class PostItem extends StatefulWidget {
  final Post post;
  final bool disableTap;

  const PostItem({super.key, required this.post, this.disableTap = false});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem>
    with SingleTickerProviderStateMixin {
  late bool isLiked;
  late int likeCount;
  late int commentCount;
  late int shareCount;
  late int viewsCount;
  bool showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLiked ?? false;
    likeCount = int.tryParse(widget.post.likesCount ?? '0') ?? 0;
    commentCount = int.tryParse(widget.post.commentsCount ?? '0') ?? 0;
    shareCount = widget.post.sharesCount ?? 0;
    viewsCount = widget.post.viewsCount ?? 0;
    // Record view when post enters the feed (fire-and-forget, deduplicated)
    ViewTracker.instance.track(widget.post.id);
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _toggleLike() async {
    HapticFeedback.mediumImpact();

    final postCubit = getIt<PostCubit>();

    if (!isLiked) {
      setState(() => showHeart = true);
      await _heartController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      await _heartController.reverse();
      setState(() => showHeart = false);
    }

    await postCubit.toggleLike(
      widget.post,
      onOptimisticUpdate: (newIsLiked, newLikeCount) {
        setState(() {
          isLiked = newIsLiked;
          likeCount = newLikeCount;
        });
      },
      onRevert: () {
        setState(() {
          isLiked = !isLiked;
          likeCount += isLiked ? 1 : -1;
        });
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ColorManager.primaryBlack,
            content: Text(
              error,
              style: TextStyles.font12Medium.copyWith(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
        );
      },
    );
  }

  void _openComments(String postId) async {
    final commentCubit = getIt<CommentCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: 220,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              S.of(context).commentsLabel,
              style: TextStyles.font18Semibold,
            ),
            const Expanded(child: Center(child: LottieLoader())),
          ],
        ),
      ),
    );

    final result = await commentCubit.getPostComments(postId);
    Navigator.pop(context);

    result.when(
      success: (comments) {
        setState(() => commentCount = comments.length);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => CommentsSheet(
            comments: comments,
            postId: postId,
            initialCommentsCount: comments.length,
            onCommentCreated: (Comment newComment) {
              setState(() => commentCount++);
            },
          ),
        );
      },
      failure: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).failedToLoadComments)),
        );
      },
    );
  }

  void _sharePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareSheet(
        post: widget.post,
        onShare: (caption) async {
          await getIt<PostCubit>().sharePost(widget.post, caption: caption);
          if (mounted) {
            Navigator.pop(context);
            setState(() => shareCount++);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final shadowColor = isDark ? Colors.transparent : Colors.black.withOpacity(0.05);
    final post = widget.post;
    final hasBadge = post.sourcePlatform != null && post.sourceUrl != null;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tappable zone (opens post detail) ───────────────────────
          GestureDetector(
            onTap: widget.disableTap ? null : () {
              HomeCubit? homeCubit;
              try { homeCubit = context.read<HomeCubit>(); } catch (_) {}
              Navigator.push(
                context,
                FadeSlidePageRoute(
                  page: homeCubit != null
                      ? BlocProvider.value(
                          value: homeCubit,
                          child: PostDetailScreen(post: post),
                        )
                      : PostDetailScreen(post: post),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 14.h, 8.w, 10.h),
                  child: PostHeader(post: post, onMoreTapped: () {}),
                ),

                // Shared original post card
                if (post.originalPost != null)
                  SharedPostCard(
                    originalPost: post.originalPost!,
                    onTap: () {
                      HomeCubit? homeCubit;
                      try { homeCubit = context.read<HomeCubit>(); } catch (_) {}
                      Navigator.push(
                        context,
                        FadeSlidePageRoute(
                          page: homeCubit != null
                              ? BlocProvider.value(
                                  value: homeCubit,
                                  child: PostDetailScreen(post: post.originalPost!),
                                )
                              : PostDetailScreen(post: post.originalPost!),
                        ),
                      );
                    },
                  ),

                // Content + images
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: PostContent(
                    post: post,
                    onImageDoubleTap: _toggleLike,
                    showHeartAnimation: showHeart,
                    heartAnimation: _scaleAnimation,
                    onVideoTap: (_) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => ReelsScreen(initialPost: post),
                      ),
                    ),
                  ),
                ),

                // Divider + actions
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Column(children: [
                    verticalSpace(12),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    verticalSpace(10),
                  ]),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, hasBadge ? 10.h : 14.h),
                  child: PostActions(
                    isLiked: isLiked,
                    likeCount: likeCount,
                    commentCount: commentCount,
                    shareCount: shareCount,
                    viewsCount: viewsCount,
                    onLikeTap: _toggleLike,
                    onCommentTap: () => _openComments(post.id.toString()),
                    onShareTap: _sharePost,
                  ),
                ),
              ],
            ),
          ),

          // ── Platform play badge — outside the tap zone so it gets its own press ──
          if (hasBadge)
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: _PlatformPlayBadge(
                platform: post.sourcePlatform!,
                url: post.sourceUrl!,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Platform play badge ───────────────────────────────────────────────────────

class _PlatformPlayBadge extends StatelessWidget {
  const _PlatformPlayBadge({required this.platform, required this.url});
  final String platform;
  final String url;

  bool get _isInstagram => platform == 'instagram';
  bool get _isTikTok    => platform == 'tiktok';
  bool get _isSpotify   => platform == 'spotify';

  String get _label {
    if (_isInstagram) return 'Play on Instagram';
    if (_isTikTok)    return 'Play on TikTok';
    if (_isSpotify)   return 'Play on Spotify';
    return 'Open link';
  }

  String get _logoUrl {
    if (_isInstagram) return 'https://logo.clearbit.com/instagram.com';
    if (_isTikTok)    return 'https://logo.clearbit.com/tiktok.com';
    return 'https://logo.clearbit.com/spotify.com';
  }

  Color _bgColor(bool isDark) {
    if (_isInstagram) return const Color(0x1FDD2A7B);
    if (_isTikTok)    return isDark ? const Color(0x1A69C9D0) : const Color(0x12010101);
    return const Color(0x121DB954);
  }

  Color _borderColor(bool isDark) {
    if (_isInstagram) return const Color(0xFFDD2A7B);
    if (_isTikTok)    return const Color(0xFF69C9D0); // teal always
    return const Color(0xFF1DB954);
  }

  Color _textColor(bool isDark) {
    if (_isInstagram) return const Color(0xFFDD2A7B);
    if (_isTikTok)    return isDark ? const Color(0xFF69C9D0) : const Color(0xFF010101);
    return const Color(0xFF1DB954);
  }

  List<BoxShadow> _glow(bool isDark) {
    if (_isInstagram) {
      return [BoxShadow(color: const Color(0x33DD2A7B), blurRadius: 8, spreadRadius: 1)];
    }
    if (_isTikTok && isDark) {
      return [BoxShadow(color: const Color(0x3369C9D0), blurRadius: 8, spreadRadius: 1)];
    }
    if (_isSpotify) {
      return [BoxShadow(color: const Color(0x221DB954), blurRadius: 8, spreadRadius: 1)];
    }
    return [];
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _borderColor(isDark);
    return GestureDetector(
      onTap: _open,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: _bgColor(isDark),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: accent, width: 1),
          boxShadow: _glow(isDark),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: Image.network(
                _logoUrl,
                width: 20.r,
                height: 20.r,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.play_circle_outline_rounded,
                  size: 20.r,
                  color: _textColor(isDark),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              _label,
              style: TextStyles.font13SemiBold.copyWith(color: _textColor(isDark)),
            ),
            SizedBox(width: 6.w),
            Icon(Icons.open_in_new_rounded, size: 14.r, color: _textColor(isDark)),
          ],
        ),
      ),
    );
  }
}
