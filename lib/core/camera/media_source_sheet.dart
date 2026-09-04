import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/generated/l10n.dart';

/// What the user chose when asked where media should come from.
enum MediaSource { camera, photoLibrary, videoLibrary }

/// The "Camera / Photo / Video" chooser, in one place.
///
/// Posts and chat each had their own bottom sheet with its own paddings, its
/// own icons, and — in chat's case — hardcoded English labels in an app whose
/// every other string is localized. Worse, chat offered no camera at all, so
/// sending a photo meant leaving the app, taking it, coming back and finding
/// it in the gallery.
///
/// Rows are 56dp, comfortably past the 48dp Android and 44pt iOS minimum, and
/// each is a `ListTile` so it announces itself as a button and shows a ripple
/// on press.
class MediaSourceSheet extends StatelessWidget {
  const MediaSourceSheet({super.key, required this.allowVideo});

  final bool allowVideo;

  static Future<MediaSource?> show(
    BuildContext context, {
    bool allowVideo = true,
  }) {
    return showModalBottomSheet<MediaSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => MediaSourceSheet(allowVideo: allowVideo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: 12.h, bottom: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle. Decorative, so it is hidden from screen readers
            // rather than announced as an unlabelled shape.
            ExcludeSemantics(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: ColorManager.lightGrey,
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            _Row(
              icon: Icons.photo_camera_rounded,
              // Named for what it does, not for the hardware: "Camera" alone
              // does not say whether it takes a picture or opens a setting.
              label: allowVideo ? s.takePhotoOrVideo : s.takePhoto,
              onTap: () => Navigator.pop(context, MediaSource.camera),
              color: onSurface,
            ),
            _Row(
              icon: Icons.photo_library_rounded,
              label: s.chooseFromGallery,
              onTap: () => Navigator.pop(context, MediaSource.photoLibrary),
              color: onSurface,
            ),
            if (allowVideo)
              _Row(
                icon: Icons.video_library_rounded,
                label: s.chooseVideo,
                onTap: () => Navigator.pop(context, MediaSource.videoLibrary),
                color: onSurface,
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 16.h,
      // The icon sits beside its own visible label, so announcing it as well
      // would just repeat the row's text.
      leading: ExcludeSemantics(child: Icon(icon, size: 24.r, color: color)),
      title: Text(label, style: TextStyles.font16Medium.copyWith(color: color)),
      onTap: onTap,
    );
  }
}
