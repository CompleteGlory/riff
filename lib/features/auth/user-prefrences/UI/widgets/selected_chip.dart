import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';

class SelectedChip extends StatelessWidget {
  final int count;
  const SelectedChip({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorManager.accent,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        '$count selected',
        style: TextStyles.font12Medium.copyWith(color: ColorManager.black),
      ),
    );
  }
}
