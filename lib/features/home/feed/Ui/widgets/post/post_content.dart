// ignore_for_file: unused_element, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/utils/media_url.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/fullscsreen_image.dart';

class PostContent extends StatelessWidget {
  final Post post;
  final VoidCallback? onImageDoubleTap;
  final bool showHeartAnimation;
  final Animation<double>? heartAnimation;
  final void Function(String videoUrl)? onVideoTap;

  const PostContent({
    super.key,
    required this.post,
    this.onImageDoubleTap,
    this.showHeartAnimation = false,
    this.heartAnimation,
    this.onVideoTap,
  });


  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }

  void _handleMediaTap(BuildContext context, List<String> allMedia, int index) {
    if (_isVideo(allMedia[index])) {
      onVideoTap?.call(MediaUrl.resolveOrEmpty(allMedia[index]));
    } else {
      // Build an image-only list for the gallery, keeping the original indices
      final imageUrls =
          allMedia.where((m) => !_isVideo(m)).map(MediaUrl.resolveOrEmpty).toList();
      final imageIndex =
          allMedia.where((m) => !_isVideo(m)).toList().indexOf(allMedia[index]);
      if (imageUrls.isNotEmpty && imageIndex >= 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FullScreenImage(images: imageUrls, initialIndex: imageIndex),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = (post.media ?? []).where((e) => e.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((post.content ?? '').isNotEmpty)
          Text(post.content!, style: TextStyles.font16Medium),
        if (images.isNotEmpty) ...[
          verticalSpace(12),
          GestureDetector(
            onDoubleTap: onImageDoubleTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildImageGrid(context, images),
                if (showHeartAnimation && heartAnimation != null)
                  ScaleTransition(
                    scale: heartAnimation!,
                    child: const Icon(
                      Icons.favorite,
                      color: ColorManager.red,
                      size: 90,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageGrid(BuildContext context, List<String> images) {
    switch (images.length) {
      case 1:
        return _single(context, images, 0);
      case 2:
        return _two(context, images);
      case 3:
        return _three(context, images);
      default:
        return _fourPlus(context, images);
    }
  }

  /// Returns a video or image tile for the given index.
  Widget _mediaTile(
    BuildContext context,
    List<String> allMedia,
    int index, {
    required double height,
    double? width,
    bool rightGap = false,
    bool bottomGap = false,
  }) {
    final raw = allMedia[index];
    final resolved = MediaUrl.resolveOrEmpty(raw);
    void onTap() => _handleMediaTap(context, allMedia, index);

    if (_isVideo(raw)) {
      return _VideoCell(
        url: resolved,
        height: height,
        width: width,
        onTap: onTap,
        rightGap: rightGap,
        bottomGap: bottomGap,
      );
    }
    return _NetImg(
      url: resolved,
      height: height,
      width: width,
      onTap: onTap,
      rightGap: rightGap,
      bottomGap: bottomGap,
    );
  }

  Widget _single(BuildContext context, List<String> images, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: _mediaTile(
        context, images, index,
        width: double.infinity,
        height: 260.h,
      ),
    );
  }

  Widget _two(BuildContext context, List<String> images) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Row(
        children: [
          Expanded(
            child: _mediaTile(context, images, 0, height: 200.h, rightGap: true),
          ),
          Expanded(
            child: _mediaTile(context, images, 1, height: 200.h),
          ),
        ],
      ),
    );
  }

  Widget _three(BuildContext context, List<String> images) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _mediaTile(context, images, 0, height: 200.h, rightGap: true),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _mediaTile(context, images, 1, height: 99.h, bottomGap: true),
                _mediaTile(context, images, 2, height: 99.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fourPlus(BuildContext context, List<String> images) {
    final extra = images.length - 4;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _mediaTile(context, images, 0,
                    height: 140.h, rightGap: true, bottomGap: true),
              ),
              Expanded(
                child: _mediaTile(context, images, 1,
                    height: 140.h, bottomGap: true),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _mediaTile(context, images, 2,
                    height: 140.h, rightGap: true),
              ),
              Expanded(
                child: extra > 0
                    ? _MoreCell(
                        url: MediaUrl.resolveOrEmpty(images[3]),
                        extra: extra,
                        onTap: () => _handleMediaTap(context, images, 3),
                        height: 140.h,
                      )
                    : _mediaTile(context, images, 3, height: 140.h),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Network image tile
// ---------------------------------------------------------------------------

class _NetImg extends StatelessWidget {
  const _NetImg({
    required this.url,
    required this.height,
    required this.onTap,
    this.width,
    this.rightGap = false,
    this.bottomGap = false,
  });

  final String url;
  final double height;
  final double? width;
  final VoidCallback onTap;
  final bool rightGap;
  final bool bottomGap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(
          right: rightGap ? 2.w : 0,
          bottom: bottomGap ? 2.h : 0,
        ),
        color: ColorManager.lighterGrey,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  color: ColorManager.lighterGrey,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
          errorBuilder: (_, __, ___) => Container(
            color: ColorManager.lighterGrey,
            child: Icon(
              Icons.broken_image_outlined,
              color: ColorManager.normalGrey,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Video thumbnail tile — shows first frame of video as background
// ---------------------------------------------------------------------------

class _VideoCell extends StatefulWidget {
  const _VideoCell({
    required this.url,
    required this.height,
    required this.onTap,
    this.width,
    this.rightGap = false,
    this.bottomGap = false,
  });

  final String url;
  final double height;
  final double? width;
  final VoidCallback onTap;
  final bool rightGap;
  final bool bottomGap;

  @override
  State<_VideoCell> createState() => _VideoCellState();
}

class _VideoCellState extends State<_VideoCell> {
  VideoPlayerController? _controller;
  bool _thumbReady = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await c.initialize();
      await c.seekTo(Duration.zero); // park on first frame
      if (mounted) {
        setState(() {
          _controller = c;
          _thumbReady = true;
        });
      } else {
        c.dispose();
      }
    } catch (_) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        margin: EdgeInsets.only(
          right: widget.rightGap ? 2.w : 0,
          bottom: widget.bottomGap ? 2.h : 0,
        ),
        color: const Color(0xFF1A1A1A),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // First-frame thumbnail
            if (_thumbReady && _controller != null)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            // Play icon overlay
            Center(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(10.r),
                child: SvgPicture.asset(
                  'assets/svgs/play.svg',
                  width: 26.r,
                  height: 26.r,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "+N more" overlay cell
// ---------------------------------------------------------------------------

class _MoreCell extends StatelessWidget {
  const _MoreCell({
    required this.url,
    required this.extra,
    required this.onTap,
    required this.height,
  });

  final String url;
  final int extra;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(url, fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(0.52)),
            Center(
              child: Text(
                '+$extra',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
