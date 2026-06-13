import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';

class AppButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  /// true = outlined/secondary style; false = lime accent primary CTA
  final bool isWhite;
  final double? width;
  final IconData? icon;
  final String? image;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.isWhite,
    this.width,
    this.icon,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Primary (lime CTA): always lime bg + black text
    // Secondary (outlined): border + theme-appropriate text
    final bgColor   = isWhite ? Colors.transparent : ColorManager.accent;
    final textColor = isWhite
        ? (isDark ? ColorManager.white : ColorManager.black)
        : ColorManager.black;
    final borderColor = isWhite
        ? (isDark ? const Color(0xFF444444) : ColorManager.black)
        : Colors.transparent;

    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  if (icon != null || image != null) horizontalSpace(12.w),
                  if (icon != null)
                    Icon(icon, color: textColor, size: 20),
                  if (image != null)
                    SvgPicture.asset(
                      image!,
                      width: 20.w,
                      height: 20.h,
                      colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
