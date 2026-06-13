import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/features/home/core/UI/widgets/bottom_nav_item.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';

class AppBottomNav extends StatelessWidget {
  final HomeCubit cubit;
  const AppBottomNav({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReels = cubit.currentIndex == 3;

    // Glass tint: dark/reels = near-black frosted, light = white frosted
    final Color glassFill = isReels
        ? Colors.black.withValues(alpha: 0.45)
        : isDark
            ? const Color(0xFF1A1A1A).withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.72);

    final Color glassBorder = isReels
        ? Colors.white.withValues(alpha: 0.12)
        : isDark
            ? Colors.white.withValues(alpha: 0.09)
            : Colors.white.withValues(alpha: 0.90);

    return Container(
      // Transparent outer container — body will extend behind this
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(28.w, 6.h, 28.w, 12.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: glassFill,
                  borderRadius: BorderRadius.circular(36.r),
                  border: Border.all(color: glassBorder, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark || isReels ? 0.40 : 0.10),
                      blurRadius: 28,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      BottomNavItem(
                          index: 0,
                          cubit: cubit,
                          svgPath: 'assets/svgs/home.svg',
                          filledSvgPath: 'assets/svgs/home_filled.svg'),
                      BottomNavItem(
                          index: 1,
                          cubit: cubit,
                          svgPath: 'assets/svgs/search.svg',
                          filledSvgPath: 'assets/svgs/search_filled.svg'),
                      BottomNavItem(
                          index: 2,
                          cubit: cubit,
                          svgPath: 'assets/svgs/plus.svg',
                          filledSvgPath: 'assets/svgs/plus_filled.svg'),
                      BottomNavItem(
                          index: 3,
                          cubit: cubit,
                          svgPath: 'assets/svgs/reels.svg',
                          filledSvgPath: 'assets/svgs/reels_filled.svg'),
                      BottomNavItem(
                          index: 4,
                          cubit: cubit,
                          svgPath: 'assets/svgs/profile.svg',
                          filledSvgPath: 'assets/svgs/profile_filled.svg'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
