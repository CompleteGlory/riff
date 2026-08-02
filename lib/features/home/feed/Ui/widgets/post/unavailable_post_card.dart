import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/generated/l10n.dart';

/// Stands in for the quoted post inside a share whose original has been
/// deleted.
///
/// Deliberately quiet: the share itself is still the user's post and stays the
/// focus of the card, so this is one line saying what happened plus a smaller
/// line about why it might have.
class UnavailablePostCard extends StatelessWidget {
  const UnavailablePostCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : ColorManager.lighterGrey,
        ),
        borderRadius: BorderRadius.circular(12.r),
        color: isDark ? const Color(0xFF252525) : ColorManager.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.visibility_off_outlined,
            size: 18.r,
            color: ColorManager.normalGrey,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.postUnavailableTitle,
                  style: TextStyles.font13SemiBold.copyWith(
                    color: ColorManager.normalGrey,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  s.postUnavailableReason,
                  style: TextStyles.font12Medium.copyWith(
                    color: ColorManager.normalGrey,
                    fontSize: 10.sp,
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
