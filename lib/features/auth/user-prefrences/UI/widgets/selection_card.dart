import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';

class SelectionCard extends StatelessWidget {
  final String name;
  final String image;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectionCard({
    super.key,
    required this.name,
    required this.image,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final labelBg = isSelected
        ? ColorManager.accent
        : (isDark ? const Color(0xFF252525) : Colors.white);
    final labelText = isSelected
        ? ColorManager.black
        : (isDark ? Colors.white : ColorManager.primaryBlack);
    final borderColor = isSelected
        ? ColorManager.accent
        : (isDark ? const Color(0xFF3A3A3A) : ColorManager.lighterGrey);
    final imageBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? ColorManager.accent.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: isSelected ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image area
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: imageBg,
                      child: Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Image.asset(
                          image,
                          fit: BoxFit.contain,
                          // White tint in dark mode for contrast
                          color: isDark ? Colors.white : null,
                          colorBlendMode: isDark ? BlendMode.srcIn : null,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.music_note,
                            size: 36.r,
                            color: isDark ? Colors.white54 : ColorManager.normalGrey,
                          ),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 10.h,
                        right: 10.w,
                        child: Container(
                          width: 26.r,
                          height: 26.r,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: ColorManager.accent,
                            size: 15.r,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Label bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                color: labelBg,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyles.font14semiBold.copyWith(color: labelText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16.r,
                        color: ColorManager.black,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
