import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/fullscsreen_image.dart';

class PostContent extends StatelessWidget {
  final Post post;
  final VoidCallback? onImageDoubleTap;
  final VoidCallback? onImageTap;
  final bool showHeartAnimation;
  final Animation<double>? heartAnimation;

  const PostContent({
    super.key,
    required this.post,
    this.onImageDoubleTap,
    this.onImageTap,
    this.showHeartAnimation = false,
    this.heartAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final mediaUrl = post.media?.firstWhere(
          (e) => e.isNotEmpty,
          orElse: () => '',
        ) ??
        '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post Text Content
        Text(post.content ?? "", style: TextStyles.font16Medium),
        verticalSpace(16),

        // Post Image with Heart Animation
        if (mediaUrl.isNotEmpty)
          GestureDetector(
            onDoubleTap: onImageDoubleTap,
            onTap: onImageTap ?? () => _openImage(context, mediaUrl),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.asset(
                    mediaUrl,
                    width: double.infinity,
                    height: 220.h,
                    fit: BoxFit.cover,
                  ),
                ),
                if (showHeartAnimation && heartAnimation != null)
                  ScaleTransition(
                    scale: heartAnimation!,
                    child: const Icon(
                      Icons.favorite,
                      color: ColorManager.red,
                      size: 100,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _openImage(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullScreenImage(imageUrl: imageUrl)),
    );
  }
}
