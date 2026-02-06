import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:riff/core/themes/colors/color_manager.dart';

class PostActions extends StatelessWidget {
  final bool isLiked;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  const PostActions({
    super.key,
    required this.isLiked,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Like Button
        GestureDetector(
          onTap: onLikeTap,
          child: SvgPicture.asset(
            isLiked ? "assets/svgs/Heart-filled.svg" : "assets/svgs/Heart.svg",
            width: 24.w,
            height: 24.h,
            color:
                isLiked ? ColorManager.red : ColorManager.primaryBlack,
          ),
        ),

        // Comment Button
        GestureDetector(
          onTap: onCommentTap,
          child: SvgPicture.asset(
            "assets/svgs/Chat.svg",
            width: 24.w,
            height: 24.h,
            color: ColorManager.primaryBlack,
          ),
        ),

        // Share Button
        GestureDetector(
          onTap: onShareTap,
          child: SvgPicture.asset(
            "assets/svgs/share.svg",
            width: 32.w,
            height: 32.h,
            color: ColorManager.primaryBlack,
          ),
        ),
      ],
    );
  }
}
