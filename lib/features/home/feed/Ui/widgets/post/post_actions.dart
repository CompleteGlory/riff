// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
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
      children: [
        // Like
        _ActionButton(
          svgAsset: isLiked
              ? 'assets/svgs/Heart-filled.svg'
              : 'assets/svgs/Heart.svg',
          color: isLiked ? ColorManager.red : ColorManager.normalGrey,
          label: _formatCount(likeCount),
          onTap: onLikeTap,
        ),
        SizedBox(width: 20.w),
        // Comment
        _ActionButton(
          svgAsset: 'assets/svgs/Chat.svg',
          color: ColorManager.normalGrey,
          label: _formatCount(commentCount),
          onTap: onCommentTap,
        ),
        const Spacer(),
        // Share
        GestureDetector(
          onTap: onShareTap,
          child: SvgPicture.asset(
            'assets/svgs/share.svg',
            width: 22.w,
            height: 22.h,
            color: ColorManager.normalGrey,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.svgAsset,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final String svgAsset;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            svgAsset,
            width: 22.w,
            height: 22.h,
            color: color,
          ),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyles.font12semiBold.copyWith(
              color: ColorManager.normalGrey,
            ),
          ),
        ],
      ),
    );
  }
}
