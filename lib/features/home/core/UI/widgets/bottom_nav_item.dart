import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';

class BottomNavItem extends StatelessWidget {
  final int index;
  final HomeCubit cubit;
  final String svgPath;
  final String filledSvgPath;

  const BottomNavItem({
    super.key,
    required this.index,
    required this.cubit,
    required this.svgPath,
    required this.filledSvgPath,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = cubit.currentIndex == index;
    final isReels = cubit.currentIndex == 3;

    // Icon color: lime when active, muted otherwise
    // On the reels dark overlay, inactive icons are white/translucent
    final Color iconColor = isActive
        ? ColorManager.accent
        : (isReels
            ? Colors.white.withValues(alpha: 0.45)
            : isDark
                ? const Color(0xFF555555)
                : const Color(0xFF999999));

    return GestureDetector(
      onTap: () => cubit.changeScreen(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          // Active tab gets a subtle lime pill behind it
          color: isActive
              ? ColorManager.accent.withValues(alpha: isDark || isReels ? 0.18 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: SvgPicture.asset(
          isActive ? filledSvgPath : svgPath,
          height: 24.h,
          width: 24.w,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
      ),
    );
  }
}
