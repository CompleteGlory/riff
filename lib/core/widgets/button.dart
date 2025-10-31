import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';

class AppButton extends StatelessWidget {
  final Function() onPressed;
  final String text;
  final bool isWhite;
  final double ? width;
  final IconData ? icon;
  
  const AppButton({
    super.key, 
    required this.onPressed, 
    required this.text, 
    required this.isWhite, this.width, this.icon
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: 49,
      decoration: ShapeDecoration(
        color: isWhite ? Colors.white : ColorManager.primaryBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isWhite 
              ? const BorderSide(color: Colors.black, width: 1) // Add black border if isWhite is true
              : BorderSide.none, // No border if isWhite is false
        ),
      ),
      child: TextButton(
        onPressed: onPressed, // Assign the function as a callback
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyles.font18Semibold.copyWith(
                color: isWhite ? Colors.black : Colors.white,
              ),
            ),
            if(icon != null)
            horizontalSpace(10.w),
            if(icon != null)
            Icon(icon,color: isWhite?Colors.black:Colors.white,),
          ],
        ),
      ),
    );
  }
}