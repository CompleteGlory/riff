import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';

class SelectionCard extends StatelessWidget {
  final String name;
  final String image;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectionCard({super.key, 
    required this.name,
    required this.image,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? ColorManager.primaryBlack : ColorManager.lighterGrey,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? ColorManager.primaryBlack.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05),
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
              // Image takes most of the card
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: ColorManager.lighterGrey,
                        child: Icon(
                          Icons.music_note,
                          size: 36.r,
                          color: ColorManager.normalGrey,
                        ),
                      ),
                    ),

                    // Selected checkmark overlay
                    if (isSelected)
                      Positioned(
                        top: 10.h,
                        right: 10.w,
                        child: Container(
                          width: 26.r,
                          height: 26.r,
                          decoration: BoxDecoration(
                            color: ColorManager.primaryBlack,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: ColorManager.white,
                            size: 15.r,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Clean white label bar at the bottom
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                color: isSelected
                    ? ColorManager.primaryBlack
                    : ColorManager.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyles.font14semiBold.copyWith(
                          color: isSelected
                              ? ColorManager.white
                              : ColorManager.primaryBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16.r,
                        color: ColorManager.white,
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
