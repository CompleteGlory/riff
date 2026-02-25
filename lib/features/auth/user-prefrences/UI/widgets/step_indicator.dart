import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';

class StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const StepIndicator({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: active ? 28.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: active ? ColorManager.primaryBlack : ColorManager.lighterGrey,
            borderRadius: BorderRadius.circular(4.r),
          ),
        );
      }),
    );
  }
}