// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';
import 'package:riff/features/home/feed/Ui/widgets/comments/comment_sheet.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/share_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/posts/post_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/comments/comment_cubit.dart';
import 'package:riff/features/home/user_profile/ui/user_profile_screen.dart';

/// Full-screen reel card.
///
/// The [controller] and [isReady] are managed by the parent [_ReelsBodyState]
/// so controllers persist across page swipes (±2 cache radius).
class ReelItem extends StatefulWidget {
  final Post post;
  final bool isActive;

  /// Pre-initialized controller from the parent cache. May be null while
  /// the controller is still loading.
  final VideoPlayerController? controller;

  /// True once [controller] has been initialized and is ready to play.
  final bool isReady;

  const ReelItem({
    super.key,
    required this.post,
    required this.isActive,
    this.controller,
    this.isReady = false,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  bool _showIcon = false;
  bool _lastActionWasPause = false;

  // Like / comment / share state (local optimistic copy).
  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;
  late int _shareCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked ?? false;
    _likeCount = int.tryParse(widget.post.likesCount ?? '0') ?? 0;
    _commentCount = int.tryParse(widget.post.commentsCount ?? '0') ?? 0;
    _shareCount = widget.post.sharesCount ?? 0;
  }

  // ── Tap to pause / resume ────────────────────────────────────────────────

  void _togglePlay() {
    final c = widget.controller;
    if (c == null || !widget.isReady) return;
    final wasPlaying = c.value.isPlaying;
    wasPlaying ? c.pause() : c.play();
    setState(() {
      _lastActionWasPause = wasPlaying;
      _showIcon = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showIcon = false);
    });
  }

  // ── Double-tap to like ───────────────────────────────────────────────────

  void _toggleLike() async {
    HapticFeedback.mediumImpact();
    final postCubit = getIt<PostCubit>();
    final current = Post(
      id: widget.post.id,
      author: widget.post.author,
      content: widget.post.content,
      createdAt: widget.post.createdAt,
      updatedAt: widget.post.updatedAt,
      isLiked: _isLiked,
      likesCount: _likeCount.toString(),
      media: widget.post.media,
      authorId: widget.post.authorId,
      likes: widget.post.likes,
      comments: widget.post.comments,
      commentsCount: widget.post.commentsCount,
    );
    await postCubit.toggleLike(
      current,
      onOptimisticUpdate: (newLiked, newCount) {
        if (mounted) setState(() { _isLiked = newLiked; _likeCount = newCount; });
      },
      onRevert: () {
        if (mounted) {
          setState(() { _isLiked = !_isLiked; _likeCount += _isLiked ? 1 : -1; });
        }
      },
      onError: (_) {},
    );
  }

  // ── Comments ─────────────────────────────────────────────────────────────

  void _openComments() async {
    final commentCubit = getIt<CommentCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const Center(
          child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
    );

    final result = await commentCubit.getPostComments(widget.post.id.toString());
    Navigator.pop(context);

    result.when(
      success: (comments) {
        if (mounted) setState(() => _commentCount = comments.length);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Padding(
            padding: EdgeInsets.all(16.w),
            child: CommentsSheet(
              comments: comments,
              postId: widget.post.id.toString(),
              initialCommentsCount: comments.length,
              onCommentCreated: (Comment _) {
                if (mounted) setState(() => _commentCount++);
              },
            ),
          ),
        );
      },
      failure: (_) {},
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
            setState(() => _shareCount++);
          }
        },
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1_000_000) return '${(n / 1_000_000).toStringAsFixed(1)}M';
    if (n >= 1_000) return '${(n / 1_000).toStringAsFixed(1)}K';
    return '$n';
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isReady = widget.isReady;

    return GestureDetector(
      onTap: _togglePlay,
      onDoubleTap: _toggleLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background.
          Container(color: Colors.black),

          // Video or loading indicator.
          if (isReady && controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36.r,
                    height: 36.r,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Loading video…',
                    style: TextStyles.font12Medium.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),

          // Play / pause icon flash.
          if (_showIcon)
            Center(
              child: Icon(
                _lastActionWasPause
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                size: 72.r,
                color: Colors.white70,
              ),
            ),

          // Bottom: @username + caption.
          Positioned(
            left: 16.w,
            right: 80.w,
            bottom: 60.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    final authorId = widget.post.author?.id;
                    if (authorId == null) return;
                    HomeCubit? homeCubit;
                    try { homeCubit = context.read<HomeCubit>(); } catch (_) {}
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => homeCubit != null
                            ? BlocProvider.value(
                                value: homeCubit,
                                child: UserProfileScreen(userId: authorId),
                              )
                            : UserProfileScreen(userId: authorId),
                      ),
                    );
                  },
                  child: Text(
                    '@${widget.post.author?.username ?? ''}',
                    style: TextStyles.font14semiBold.copyWith(color: Colors.white),
                  ),
                ),
                if ((widget.post.content ?? '').isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    widget.post.content ?? '',
                    style: TextStyles.font12Medium.copyWith(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Right-side action buttons.
          Positioned(
            right: 12.w,
            bottom: 60.h,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReelAction(
                  label: _fmt(_likeCount),
                  onTap: _toggleLike,
                  child: SvgPicture.asset(
                    _isLiked ? 'assets/svgs/Heart-filled.svg' : 'assets/svgs/Heart.svg',
                    width: 28.w,
                    height: 28.h,
                    color: _isLiked ? ColorManager.red : Colors.white,
                  ),
                ),
                SizedBox(height: 20.h),
                _ReelAction(
                  label: _fmt(_commentCount),
                  onTap: _openComments,
                  child: SvgPicture.asset(
                    'assets/svgs/Chat.svg',
                    width: 28.w,
                    height: 28.h,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20.h),
                _ReelAction(
                  label: _shareCount > 0 ? _fmt(_shareCount) : '',
                  onTap: _sharePost,
                  child: SvgPicture.asset(
                    'assets/svgs/share.svg',
                    width: 28.w,
                    height: 28.h,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ────────────────────────────────────────────────────────────

class _ReelAction extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback onTap;

  const _ReelAction({required this.child, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          if (label.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(label, style: TextStyles.font12Medium.copyWith(color: Colors.white)),
          ],
        ],
      ),
    );
  }
}
