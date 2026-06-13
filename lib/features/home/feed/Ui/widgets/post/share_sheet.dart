// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/shared_post_card.dart';

/// Bottom sheet that lets the user write an optional caption before sharing.
class ShareSheet extends StatefulWidget {
  /// The post being shared (the original post, not a share-of-share).
  final Post post;

  /// Called with the trimmed caption when the user taps Share.
  final Future<void> Function(String caption) onShare;

  const ShareSheet({super.key, required this.post, required this.onShare});

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final _captionController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _loading = true);
    await widget.onShare(_captionController.text.trim());
    // The parent closes the sheet on success, so we only reset on failure.
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: ColorManager.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(0, 12.h, 0, bottomPad + 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: ColorManager.lighterGrey,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          verticalSpace(16),

          // Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text('Share Post', style: TextStyles.font16Medium),
          ),
          verticalSpace(12),

          // Preview of the post being shared
          SharedPostCard(originalPost: widget.post),

          verticalSpace(12),

          // Caption field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _captionController,
              minLines: 2,
              maxLines: 5,
              autofocus: false,
              textInputAction: TextInputAction.newline,
              style: TextStyles.font14Medium,
              decoration: InputDecoration(
                hintText: 'Write a caption… (optional)',
                hintStyle: TextStyles.font14Medium.copyWith(
                  color: ColorManager.normalGrey,
                ),
                filled: true,
                fillColor: ColorManager.lighterGrey.withValues(alpha: 0.5),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          verticalSpace(16),

          // Share button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primaryBlack,
                  disabledBackgroundColor:
                      ColorManager.primaryBlack.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _loading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Share',
                        style: TextStyles.font16Medium
                            .copyWith(color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
