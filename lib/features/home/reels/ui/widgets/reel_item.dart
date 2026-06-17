// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:video_player/video_player.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
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
import 'package:riff/features/home/follow/logic/cubit/follow_cubit.dart';
import 'package:riff/features/home/feed/logic/view_tracker.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_options.dart';
import 'package:riff/features/home/feed/Ui/post_detail_screen.dart';

/// Full-screen reel card.
class ReelItem extends StatefulWidget {
  final Post post;
  final bool isActive;
  final bool showBackButton;
  final VideoPlayerController? controller;
  final bool isReady;

  const ReelItem({
    super.key,
    required this.post,
    required this.isActive,
    this.controller,
    this.isReady = false,
    this.showBackButton = false,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  bool _showIcon = false;
  bool _lastActionWasPause = false;

  // Like / comment / share (optimistic)
  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;
  late int _shareCount;

  // Follow state
  bool _isFollowing = false;
  bool _followLoading = false;
  String? _myUserId;

  // Slider drag
  bool _draggingSlider = false;
  double _sliderValue = 0;

  // Internal thumbnail controller (shows first frame while parent loads)
  VideoPlayerController? _thumbController;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked ?? false;
    _likeCount = int.tryParse(widget.post.likesCount ?? '0') ?? 0;
    _commentCount = int.tryParse(widget.post.commentsCount ?? '0') ?? 0;
    _shareCount = widget.post.sharesCount ?? 0;
    _loadMyId();
    ViewTracker.instance.track(widget.post.id);
    // Attach listener immediately if controller is already ready on first build.
    if (widget.isReady && widget.controller != null) {
      widget.controller!.addListener(_onControllerUpdate);
    } else {
      // Parent controller not ready yet — load a thumbnail controller so we
      // can show the first frame instead of a black screen.
      _loadThumb();
    }
  }

  String? _extractVideoUrl() {
    for (final m in widget.post.media ?? []) {
      final lower = m.toLowerCase();
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') ||
          lower.endsWith('.webm') || lower.endsWith('.avi') ||
          lower.endsWith('.mkv')) {
        return m.startsWith('http')
            ? m
            : '${ApiConstants.apiBASEURL}$m';
      }
    }
    return null;
  }

  Future<void> _loadThumb() async {
    final url = _extractVideoUrl();
    if (url == null) return;
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await c.initialize();
      await c.seekTo(Duration.zero);
      if (mounted && !widget.isReady) {
        setState(() { _thumbController = c; });
      } else {
        c.dispose();
      }
    } catch (_) {
      c.dispose();
    }
  }

  void _disposeThumb() {
    _thumbController?.dispose();
    _thumbController = null;
  }

  @override
  void didUpdateWidget(ReelItem old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      // Controller instance swapped — reattach.
      old.controller?.removeListener(_onControllerUpdate);
      if (widget.isReady && widget.controller != null) {
        widget.controller!.addListener(_onControllerUpdate);
      }
    } else if (!old.isReady && widget.isReady) {
      // Controller became ready — attach now and drop thumbnail.
      widget.controller?.addListener(_onControllerUpdate);
      _disposeThumb();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerUpdate);
    _disposeThumb();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted || _draggingSlider) return;
    final c = widget.controller;
    if (c == null) return;
    final dur = c.value.duration.inMilliseconds;
    if (dur <= 0) return;
    final pos = c.value.position.inMilliseconds.clamp(0, dur);
    setState(() => _sliderValue = pos / dur);
  }

  Future<void> _loadMyId() async {
    final id = await SharedPrefHelper.getString(SharedPrefKeys.userId) as String?;
    if (mounted) setState(() => _myUserId = id ?? '');
  }

  bool get _isOwnPost =>
      _myUserId != null &&
      _myUserId!.isNotEmpty &&
      widget.post.author?.id == _myUserId;

  // ── Tap to pause / resume ───────────────────────────────────────────────

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

  // ── Double-tap to like ──────────────────────────────────────────────────

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

  // ── Follow / unfollow ───────────────────────────────────────────────────

  Future<void> _follow() async {
    final authorId = widget.post.author?.id;
    if (authorId == null || _followLoading) return;
    setState(() { _followLoading = true; _isFollowing = true; });
    try {
      await getIt<FollowCubit>().follow(authorId);
    } catch (_) {
      if (mounted) setState(() => _isFollowing = false);
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  // ── Comments ────────────────────────────────────────────────────────────

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

  void _openOptions() {
    showPostOptions(
      isMine: _isOwnPost,
      context: context,
      post: widget.post,
    );
  }

  void _openFullPost() {
    HomeCubit? homeCubit;
    try { homeCubit = context.read<HomeCubit>(); } catch (_) {}
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => homeCubit != null
            ? BlocProvider.value(
                value: homeCubit,
                child: PostDetailScreen(post: widget.post),
              )
            : PostDetailScreen(post: widget.post),
      ),
    );
  }

  void _goToAuthorProfile() {
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
    final bottomInset = MediaQuery.of(context).padding.bottom + 8.h;

    // Duration string for right side of slider
    String durationLabel() {
      if (controller == null || !isReady) return '';
      final pos = controller.value.position;
      final dur = controller.value.duration;
      String fmt(Duration d) =>
          '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
          '${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
      return '${fmt(pos)} / ${fmt(dur)}';
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background ──────────────────────────────────────────────────────
        Container(color: Colors.black),

        // ── Video / thumbnail / spinner ─────────────────────────────────────
        GestureDetector(
          onTap: _togglePlay,
          onDoubleTap: _toggleLike,
          child: SizedBox.expand(
            child: isReady && controller != null
                ? Center(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  )
                : const Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    ),
                  ),
          ),
        ),

        // ── Play/pause flash icon ────────────────────────────────────────────
        if (_showIcon)
          IgnorePointer(
            child: Center(
              child: Icon(
                _lastActionWasPause
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                size: 72.r,
                color: Colors.white70,
              ),
            ),
          ),

        // ── Back button ──────────────────────────────────────────────────────
        if (widget.showBackButton)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 4,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 22),
            ),
          ),

        // ── Bottom-left: @username + caption + follow button ─────────────────
        Positioned(
          left: 16.w,
          right: 80.w,
          bottom: bottomInset + 56.h, // leave room for slider
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Author row: @username + follow button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _goToAuthorProfile,
                    child: Text(
                      '@${widget.post.author?.username ?? ''}',
                      style: TextStyles.font14semiBold
                          .copyWith(color: Colors.white),
                    ),
                  ),
                  if (!_isOwnPost && !_isFollowing) ...[
                    SizedBox(width: 10.w),
                    GestureDetector(
                      onTap: _follow,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.2),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: _followLoading
                            ? SizedBox(
                                width: 12.r,
                                height: 12.r,
                                child: const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 1.5),
                              )
                            : Text(
                                'Follow',
                                style: TextStyles.font12semiBold
                                    .copyWith(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
              if ((widget.post.content ?? '').isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  widget.post.content ?? '',
                  style: TextStyles.font12Medium
                      .copyWith(color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // ── Bottom-right: like / comment / share ─────────────────────────────
        Positioned(
          right: 12.w,
          bottom: bottomInset + 56.h,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReelAction(
                label: _fmt(_likeCount),
                onTap: _toggleLike,
                child: SvgPicture.asset(
                  _isLiked
                      ? 'assets/svgs/Heart-filled.svg'
                      : 'assets/svgs/Heart.svg',
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
              SizedBox(height: 20.h),
              // View full post
              _ReelAction(
                label: '',
                onTap: _openFullPost,
                child: Icon(Icons.article_outlined,
                    size: 28.w, color: Colors.white),
              ),
              SizedBox(height: 20.h),
              // More options (edit / delete / report)
              _ReelAction(
                label: '',
                onTap: _openOptions,
                child: Icon(Icons.more_horiz,
                    size: 28.w, color: Colors.white),
              ),
            ],
          ),
        ),

        // ── Progress slider ──────────────────────────────────────────────────
        if (isReady && controller != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 8.h,
            child: _VideoSlider(
              controller: controller,
              dragging: _draggingSlider,
              value: _sliderValue,
              durationLabel: durationLabel(),
              onChangeStart: (_) {
                setState(() => _draggingSlider = true);
                controller.pause();
              },
              onChanged: (v) => setState(() => _sliderValue = v),
              onChangeEnd: (v) async {
                final dur = controller.value.duration;
                await controller.seekTo(
                    Duration(milliseconds: (v * dur.inMilliseconds).round()));
                if (widget.isActive) controller.play();
                setState(() => _draggingSlider = false);
              },
            ),
          ),
      ],
    );
  }
}

// ── Video progress slider ─────────────────────────────────────────────────────

class _VideoSlider extends StatelessWidget {
  final VideoPlayerController controller;
  final bool dragging;
  final double value;
  final String durationLabel;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _VideoSlider({
    required this.controller,
    required this.dragging,
    required this.value,
    required this.durationLabel,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (durationLabel.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 16.w, bottom: 2.h),
                child: Text(
                  durationLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'GeneralSans',
                  ),
                ),
              ),
            ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.5,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5.r),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white30,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChangeStart: onChangeStart,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ReelAction extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback onTap;

  const _ReelAction(
      {required this.child, required this.label, required this.onTap});

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
            Text(label,
                style:
                    TextStyles.font12Medium.copyWith(color: Colors.white)),
          ],
        ],
      ),
    );
  }
}
