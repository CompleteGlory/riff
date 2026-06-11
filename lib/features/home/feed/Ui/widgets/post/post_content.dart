// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/fullscsreen_image.dart';

class PostContent extends StatelessWidget {
  final Post post;
  final VoidCallback? onImageDoubleTap;
  final bool showHeartAnimation;
  final Animation<double>? heartAnimation;

  const PostContent({
    super.key,
    required this.post,
    this.onImageDoubleTap,
    this.showHeartAnimation = false,
    this.heartAnimation,
  });

  String _resolve(String url) =>
      url.startsWith('http') ? url : '${ApiConstants.apiBASEURL}$url';

  void _openGallery(BuildContext context, List<String> images, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImage(images: images, initialIndex: index),
      ),
    );
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

  Widget _single(BuildContext context, List<String> images, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: _NetImg(
        url: _resolve(images[index]),
        width: double.infinity,
        height: 260.h,
        onTap: () => _openGallery(context, images, index),
      ),
    );
  }

  Widget _two(BuildContext context, List<String> images) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Row(
        children: [
          Expanded(
            child: _NetImg(
              url: _resolve(images[0]),
              height: 200.h,
              onTap: () => _openGallery(context, images, 0),
              rightGap: true,
            ),
          ),
          Expanded(
            child: _NetImg(
              url: _resolve(images[1]),
              height: 200.h,
              onTap: () => _openGallery(context, images, 1),
            ),
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
            child: _NetImg(
              url: _resolve(images[0]),
              height: 200.h,
              onTap: () => _openGallery(context, images, 0),
              rightGap: true,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _NetImg(
                  url: _resolve(images[1]),
                  height: 99.h,
                  onTap: () => _openGallery(context, images, 1),
                  bottomGap: true,
                ),
                _NetImg(
                  url: _resolve(images[2]),
                  height: 99.h,
                  onTap: () => _openGallery(context, images, 2),
                ),
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
                child: _NetImg(
                  url: _resolve(images[0]),
                  height: 140.h,
                  onTap: () => _openGallery(context, images, 0),
                  rightGap: true,
                  bottomGap: true,
                ),
              ),
              Expanded(
                child: _NetImg(
                  url: _resolve(images[1]),
                  height: 140.h,
                  onTap: () => _openGallery(context, images, 1),
                  bottomGap: true,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _NetImg(
                  url: _resolve(images[2]),
                  height: 140.h,
                  onTap: () => _openGallery(context, images, 2),
                  rightGap: true,
                ),
              ),
              Expanded(
                child: extra > 0
                    ? _MoreCell(
                        url: _resolve(images[3]),
                        extra: extra,
                        onTap: () => _openGallery(context, images, 3),
                        height: 140.h,
                      )
                    : _NetImg(
                        url: _resolve(images[3]),
                        height: 140.h,
                        onTap: () => _openGallery(context, images, 3),
                      ),
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
