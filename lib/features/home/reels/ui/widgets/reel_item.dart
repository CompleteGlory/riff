// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:riff/core/utils/media_url.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'package:riff/generated/l10n.dart';

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
  double _bufferedValue = 0;

  // Playback speed
  double _playbackSpeed = 1.0;
  bool _isFastForward = false; // true while long-pressing right side

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
      // Apply any speed that was set before controller was ready
      if (_playbackSpeed != 1.0) {
        widget.controller?.setPlaybackSpeed(_playbackSpeed);
      }
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

    // Compute how far the video has buffered (max buffered end / duration)
    double buffered = 0;
    for (final range in c.value.buffered) {
      final end = range.end.inMilliseconds;
      if (end > buffered * dur) buffered = end / dur;
    }

    setState(() {
      _sliderValue = pos / dur;
      _bufferedValue = buffered.clamp(0.0, 1.0);
    });
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

  // ── Playback speed ──────────────────────────────────────────────────────────

  void _setSpeed(double speed) {
    setState(() => _playbackSpeed = speed);
    widget.controller?.setPlaybackSpeed(speed);
  }

  void _onLongPressRightStart(LongPressStartDetails _) {
    widget.controller?.setPlaybackSpeed(2.0);
    setState(() => _isFastForward = true);
  }

  void _onLongPressRightEnd(LongPressEndDetails _) {
    widget.controller?.setPlaybackSpeed(_playbackSpeed);
    setState(() => _isFastForward = false);
  }

  void _onLongPressRightCancel() {
    widget.controller?.setPlaybackSpeed(_playbackSpeed);
    setState(() => _isFastForward = false);
  }

  void _openOptions() {
    _showReelOptionsSheet(context);
  }

  void _showReelOptionsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final speeds = [1.0, 1.25, 1.5, 1.75, 2.0];
    final speedLabels = ['1×', '1.25×', '1.5×', '1.75×', '2×'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Theme.of(sheetCtx).dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 16.h),
              // ── Speed section ──────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Playback Speed',
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: ColorManager.normalGrey,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(speeds.length, (i) {
                  final isSelected = _playbackSpeed == speeds[i];
                  return GestureDetector(
                    onTap: () {
                      _setSpeed(speeds[i]);
                      setSheetState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorManager.accent
                            : (isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF0F0F0)),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isSelected
                              ? ColorManager.accent
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        speedLabels[i],
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.black
                              : onSurface,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 20.h),
              Divider(height: 1, color: ColorManager.lighterGrey),
              SizedBox(height: 10.h),
              // ── Post options ───────────────────────────────────────
              if (_isOwnPost) ...[
                _sheetOption(
                  svgPath: 'assets/svgs/edit.svg',
                  label: 'Edit Post',
                  color: onSurface,
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    showPostOptions(
                        isMine: true, context: context, post: widget.post);
                  },
                ),
                _sheetOption(
                  svgPath: 'assets/svgs/delete.svg',
                  label: 'Delete Post',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    showPostOptions(
                        isMine: true, context: context, post: widget.post);
                  },
                ),
              ] else ...[
                _sheetOption(
                  svgPath: 'assets/svgs/report.svg',
                  label: 'Report Post',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    showPostOptions(
                        isMine: false, context: context, post: widget.post);
                  },
                ),
              ],
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption({
    required String svgPath,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SvgPicture.asset(
        svgPath,
        width: 22.w,
        height: 22.h,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      onTap: onTap,
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

  bool get _hasVideoMedia => (widget.post.media ?? []).any((m) {
    final l = m.toLowerCase();
    return l.endsWith('.mp4') || l.endsWith('.mov') ||
           l.endsWith('.webm') || l.endsWith('.avi') || l.endsWith('.mkv');
  });

  /// True only for link-only posts (no video file) from an external platform.
  /// Posts that have a real video + a sourceUrl play normally with a small badge.
  bool get _isExternalPlatform =>
      widget.post.sourceUrl != null &&
      widget.post.sourcePlatform != null &&
      !_hasVideoMedia;

  // ── External platform reel ───────────────────────────────────────────────

  Widget _buildExternalPlatformReel(BuildContext context) {
    final post = widget.post;
    final platform = post.sourcePlatform!;
    final url = post.sourceUrl!;
    final bottomInset = MediaQuery.of(context).padding.bottom + 8.h;

    // Resolve thumbnail from post media (first image if any)
    final thumbnail = (post.media ?? [])
        .where((m) => !m.toLowerCase().endsWith('.mp4') &&
            !m.toLowerCase().endsWith('.mov') &&
            !m.toLowerCase().endsWith('.webm'))
        .map((m) => MediaUrl.resolveOrEmpty(m))
        .where((m) => m.isNotEmpty)
        .firstOrNull;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background ────────────────────────────────────────────────
        _PlatformBackground(platform: platform, thumbnail: thumbnail),

        // ── Centered platform card ────────────────────────────────────
        Center(
          child: _PlatformReelCard(
            platform: platform,
            url: url,
            thumbnail: thumbnail,
            caption: post.content,
          ),
        ),

        // ── Back button ───────────────────────────────────────────────
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

        // ── Bottom-left: @username + caption ─────────────────────────
        Positioned(
          left: 16.w,
          right: 80.w,
          bottom: bottomInset + 16.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _goToAuthorProfile,
                child: Text(
                  '@${post.author?.username ?? ''}',
                  style: TextStyles.font14semiBold.copyWith(color: Colors.white),
                ),
              ),
              if ((post.content ?? '').isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  post.content ?? '',
                  style: TextStyles.font12Medium.copyWith(color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // ── Bottom-right: like / comment / share ──────────────────────
        Positioned(
          right: 12.w,
          bottom: bottomInset + 16.h,
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
                  colorFilter: ColorFilter.mode(
                    _isLiked ? ColorManager.red : Colors.white,
                    BlendMode.srcIn,
                  ),
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
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
              SizedBox(height: 20.h),
              _ReelAction(
                label: '',
                onTap: _openFullPost,
                child: SvgPicture.asset(
                  'assets/svgs/post_details.svg',
                  width: 26.w,
                  height: 26.h,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // External platform post — show platform card instead of video player
    if (_isExternalPlatform) return _buildExternalPlatformReel(context);

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
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      // Show first-frame thumbnail while loading if available
                      if (_thumbController != null)
                        FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: _thumbController!.value.size.width,
                            height: _thumbController!.value.size.height,
                            child: VideoPlayer(_thumbController!),
                          ),
                        ),
                      const _VideoLoadingAnimation(),
                    ],
                  ),
          ),
        ),

        // ── Mid-playback buffering overlay ───────────────────────────────────
        if (isReady && controller != null && controller.value.isBuffering)
          IgnorePointer(
            child: Center(
              child: Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),

        // ── Long-press right half → 2x fast-forward ─────────────────────────
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.45,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPressStart: _onLongPressRightStart,
            onLongPressEnd: _onLongPressRightEnd,
            onLongPressCancel: _onLongPressRightCancel,
          ),
        ),

        // ── Fast-forward badge ───────────────────────────────────────────────
        if (_isFastForward)
          IgnorePointer(
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fast_forward_rounded,
                        color: Colors.white, size: 18.r),
                    SizedBox(width: 4.w),
                    Text(
                      '2×',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'GeneralSans',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Speed indicator (when non-1x set from sheet) ────────────────────
        if (_playbackSpeed != 1.0 && !_isFastForward)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.h,
            right: 16.w,
            child: IgnorePointer(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${_playbackSpeed == _playbackSpeed.truncateToDouble() ? _playbackSpeed.toInt() : _playbackSpeed}×',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'GeneralSans',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

        // ── Play/pause flash icon ────────────────────────────────────────────
        if (_showIcon)
          IgnorePointer(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(16.r),
                child: SvgPicture.asset(
                  _lastActionWasPause
                      ? 'assets/svgs/pause.svg'
                      : 'assets/svgs/play.svg',
                  width: 40.r,
                  height: 40.r,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
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
              // Platform badge above author when post has a sourceUrl
              if (!_isExternalPlatform &&
                  widget.post.sourceUrl != null &&
                  widget.post.sourcePlatform != null) ...[
                _ReelPlatformBadge(
                  platform: widget.post.sourcePlatform!,
                  url: widget.post.sourceUrl!,
                ),
                SizedBox(height: 8.h),
              ],
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
                                S.of(context).followBtn,
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
                  colorFilter: ColorFilter.mode(
                    _isLiked ? ColorManager.red : Colors.white,
                    BlendMode.srcIn,
                  ),
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
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
              SizedBox(height: 20.h),
              // View full post
              _ReelAction(
                label: '',
                onTap: _openFullPost,
                child: SvgPicture.asset(
                  'assets/svgs/post_details.svg',
                  width: 26.w,
                  height: 26.h,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
              SizedBox(height: 20.h),
              // More options (edit / delete / report)
              _ReelAction(
                label: '',
                onTap: _openOptions,
                child: SvgPicture.asset(
                  'assets/svgs/more_options.svg',
                  width: 26.w,
                  height: 26.h,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
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
              bufferedValue: _bufferedValue,
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

// ── Video loading animation ───────────────────────────────────────────────────

class _VideoLoadingAnimation extends StatefulWidget {
  const _VideoLoadingAnimation();

  @override
  State<_VideoLoadingAnimation> createState() => _VideoLoadingAnimationState();
}

class _VideoLoadingAnimationState extends State<_VideoLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale1;
  late Animation<double> _scale2;
  late Animation<double> _opacity1;
  late Animation<double> _opacity2;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Ring 1 — starts immediately
    _scale1 = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    _opacity1 = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );

    // Ring 2 — staggered half a cycle behind
    _scale2 = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.35, 1.0, curve: Curves.easeOut)),
    );
    _opacity2 = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.35, 1.0, curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ringSize = 80.0;
    const iconSize = 42.0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox(
        width: ringSize,
        height: ringSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing ring 1
            Transform.scale(
              scale: _scale1.value,
              child: Opacity(
                opacity: _opacity1.value,
                child: Container(
                  width: ringSize,
                  height: ringSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
            // Pulsing ring 2
            Transform.scale(
              scale: _scale2.value,
              child: Opacity(
                opacity: _opacity2.value,
                child: Container(
                  width: ringSize,
                  height: ringSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
            // Centre — play icon in frosted circle
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(color: Colors.white54, width: 1.5),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Video progress slider ─────────────────────────────────────────────────────

class _VideoSlider extends StatelessWidget {
  final VideoPlayerController controller;
  final bool dragging;
  final double value;
  final double bufferedValue;
  final String durationLabel;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _VideoSlider({
    required this.controller,
    required this.dragging,
    required this.value,
    required this.bufferedValue,
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
              inactiveTrackColor: Colors.white24,
              secondaryActiveTrackColor: Colors.white54,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              secondaryTrackValue: bufferedValue.clamp(0.0, 1.0),
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

// ── Platform background ────────────────────────────────────────────────────────

class _PlatformBackground extends StatelessWidget {
  final String platform;
  final String? thumbnail;
  const _PlatformBackground({required this.platform, this.thumbnail});

  @override
  Widget build(BuildContext context) {
    final bgColor = switch (platform) {
      'spotify'   => const Color(0xFF0A1A0A),
      'tiktok'    => const Color(0xFF080808),
      'instagram' => const Color(0xFF120818),
      _           => const Color(0xFF0D0D0D),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: bgColor),
        // Blurred thumbnail as background if available
        if (thumbnail != null)
          Opacity(
            opacity: 0.25,
            child: CachedNetworkImage(
              imageUrl: thumbnail!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        // Dark gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Platform reel card ─────────────────────────────────────────────────────────

class _PlatformReelCard extends StatelessWidget {
  final String platform;
  final String url;
  final String? thumbnail;
  final String? caption;

  const _PlatformReelCard({
    required this.platform,
    required this.url,
    this.thumbnail,
    this.caption,
  });

  bool get _isSpotify   => platform == 'spotify';
  bool get _isTikTok    => platform == 'tiktok';
  bool get _isInstagram => platform == 'instagram';

  String get _platformName {
    if (_isSpotify)   return 'Spotify';
    if (_isTikTok)    return 'TikTok';
    if (_isInstagram) return 'Instagram';
    return platform;
  }

  String get _buttonLabel {
    if (_isSpotify)   return 'Play on Spotify';
    if (_isTikTok)    return 'Watch on TikTok';
    if (_isInstagram) return 'Watch on Instagram';
    return 'Open link';
  }

  Color get _accentColor {
    if (_isSpotify)   return const Color(0xFF1DB954);
    if (_isTikTok)    return const Color(0xFFFF0050);
    if (_isInstagram) return const Color(0xFFDD2A7B);
    return Colors.white;
  }

  Color get _buttonTextColor {
    if (_isSpotify) return Colors.black;
    return Colors.white;
  }

  Decoration get _buttonDecoration {
    if (_isInstagram) {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF405DE6), Color(0xFF833AB4), Color(0xFFC13584),
                   Color(0xFFE1306C), Color(0xFFFD1D1D), Color(0xFFF77737)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      );
    }
    return BoxDecoration(
      color: _accentColor,
      borderRadius: BorderRadius.circular(30),
    );
  }

  IconData get _platformIcon {
    if (_isSpotify)   return Icons.music_note_rounded;
    if (_isTikTok)    return Icons.play_circle_outline_rounded;
    if (_isInstagram) return Icons.camera_alt_outlined;
    return Icons.open_in_new_rounded;
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: _accentColor.withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail
            if (thumbnail != null)
              CachedNetworkImage(
                imageUrl: thumbnail!,
                width: double.infinity,
                height: 200.h,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _PlatformIconBanner(
                  icon: _platformIcon,
                  color: _accentColor,
                ),
              )
            else
              _PlatformIconBanner(icon: _platformIcon, color: _accentColor),

            // Body
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform badge
                  Row(children: [
                    Icon(_platformIcon, size: 14, color: _accentColor),
                    SizedBox(width: 6.w),
                    Text(
                      _platformName,
                      style: TextStyles.font12semiBold.copyWith(color: _accentColor),
                    ),
                  ]),
                  if ((caption ?? '').isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      caption!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.font13SemiBold.copyWith(color: Colors.white),
                    ),
                  ],
                  SizedBox(height: 14.h),
                  // CTA button
                  GestureDetector(
                    onTap: _open,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: _buttonDecoration,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_platformIcon, size: 16, color: _buttonTextColor),
                          SizedBox(width: 8.w),
                          Text(
                            _buttonLabel,
                            style: TextStyles.font13SemiBold
                                .copyWith(color: _buttonTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformIconBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _PlatformIconBanner({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160.h,
      color: color.withOpacity(0.08),
      child: Icon(icon, size: 64, color: color.withOpacity(0.6)),
    );
  }
}

// ── Small platform badge (shown over a real video) ────────────────────────────

class _ReelPlatformBadge extends StatelessWidget {
  final String platform;
  final String url;
  const _ReelPlatformBadge({required this.platform, required this.url});

  bool get _isSpotify   => platform == 'spotify';
  bool get _isTikTok    => platform == 'tiktok';
  bool get _isInstagram => platform == 'instagram';

  String get _label {
    if (_isSpotify)   return 'Play on Spotify';
    if (_isTikTok)    return 'Watch on TikTok';
    if (_isInstagram) return 'Watch on Instagram';
    return 'Open link';
  }

  Color get _accent {
    if (_isSpotify)   return const Color(0xFF1DB954);
    if (_isTikTok)    return const Color(0xFF69C9D0);
    if (_isInstagram) return const Color(0xFFDD2A7B);
    return Colors.white70;
  }

  String get _logoUrl {
    if (_isInstagram) return 'https://logo.clearbit.com/instagram.com';
    if (_isTikTok)    return 'https://logo.clearbit.com/tiktok.com';
    return 'https://logo.clearbit.com/spotify.com';
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: _accent.withOpacity(0.6), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3.r),
              child: Image.network(
                _logoUrl,
                width: 16.r,
                height: 16.r,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.play_circle_outline_rounded, size: 16.r, color: _accent),
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              _label,
              style: TextStyles.font12semiBold.copyWith(color: _accent),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.open_in_new_rounded, size: 12, color: _accent),
          ],
        ),
      ),
    );
  }
}
