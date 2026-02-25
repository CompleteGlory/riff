// post_actions.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';

class PostActions extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  const PostActions({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Like
        GestureDetector(
          onTap: onLikeTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                isLiked
                    ? "assets/svgs/Heart-filled.svg"
                    : "assets/svgs/Heart.svg",
                width: 24.w,
                height: 24.h,
                color: isLiked ? ColorManager.red : ColorManager.primaryBlack,
              ),
              verticalSpace(4),
              Text(
                '$likeCount ${likeCount == 1 ? 'like' : 'likes'}',
                style: TextStyles.font12Medium.copyWith(
                  color: ColorManager.darkGrey,
                ),
              ),
            ],
          ),
        ),

        // Comment
        GestureDetector(
          onTap: onCommentTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                "assets/svgs/Chat.svg",
                width: 24.w,
                height: 24.h,
                color: ColorManager.primaryBlack,
              ),
              verticalSpace(4),
              Text(
                '$commentCount ${commentCount == 1 ? 'comment' : 'comments'}',
                style: TextStyles.font12Medium.copyWith(
                  color: ColorManager.darkGrey,
                ),
              ),
            ],
          ),
        ),

        // Share (no count)
        GestureDetector(
          onTap: onShareTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                "assets/svgs/share.svg",
                width: 32.w,
                height: 32.h,
                color: ColorManager.primaryBlack,
              ),
              verticalSpace(4),
              Text(
                'Share',
                style: TextStyles.font12Medium.copyWith(
                  color: ColorManager.darkGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}