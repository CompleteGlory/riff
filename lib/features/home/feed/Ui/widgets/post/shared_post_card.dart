import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/generated/l10n.dart';

/// Quoted-card widget that renders the original post inside a share post.
class SharedPostCard extends StatelessWidget {
  final Post originalPost;

  /// Optional tap handler — navigates to the full original post detail.
  final VoidCallback? onTap;

  const SharedPostCard({super.key, required this.originalPost, this.onTap});

  String _resolve(String url) =>
      url.startsWith('http') ? url : '${ApiConstants.apiBASEURL}$url';

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final author = originalPost.author;
    final media =
        (originalPost.media ?? []).where((m) => m.isNotEmpty).toList();
    final firstMedia = media.isNotEmpty ? media.first : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : ColorManager.lighterGrey,
        ),
        borderRadius: BorderRadius.circular(12.r),
        color: isDark ? const Color(0xFF252525) : ColorManager.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 6.h),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14.r,
                  backgroundImage: author?.profileImageUrl != null
                      ? NetworkImage(_resolve(author!.profileImageUrl!))
                      : null,
                  backgroundColor: isDark
                      ? const Color(0xFF2A2A2A)
                      : ColorManager.lighterGrey,
                  child: author?.profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 14.r,
                          color: ColorManager.normalGrey,
                        )
                      : null,
                ),
                horizontalSpace(8),
                Flexible(
                  child: Text(
                    author?.fullName ?? author?.username ?? s.unknown,
                    style: TextStyles.font13SemiBold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Post content text
          if ((originalPost.content ?? '').isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
              child: Text(
                originalPost.content!,
                style: TextStyles.font14Medium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // First media item (image or video placeholder)
          if (firstMedia != null)
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
              ),
              child: _isVideo(firstMedia)
                  ? Container(
                      width: double.infinity,
                      height: 160.h,
                      color: const Color(0xFF1A1A1A),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            color: Colors.white70,
                            size: 40.r,
                          ),
                          Positioned(
                            bottom: 6.h,
                            left: 8.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                s.videoLabel,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10.sp),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Image.network(
                      _resolve(firstMedia),
                      width: double.infinity,
                      height: 160.h,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              height: 160.h,
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : ColorManager.lighterGrey,
                              child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        height: 160.h,
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : ColorManager.lighterGrey,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: ColorManager.normalGrey,
                        ),
                      ),
                    ),
            ),
            verticalSpace(4),
        ],
      ),
    ), // Container
    ); // GestureDetector
  }
}
