import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';

class PostActions extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  const PostActions({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? const Color(0xFF666666) : ColorManager.normalGrey;

    return Row(
      children: [
        _ActionButton(
          svgAsset: isLiked ? 'assets/svgs/Heart-filled.svg' : 'assets/svgs/Heart.svg',
          color: isLiked ? ColorManager.red : mutedColor,
          label: _formatCount(likeCount),
          onTap: onLikeTap,
        ),
        SizedBox(width: 20.w),
        _ActionButton(
          svgAsset: 'assets/svgs/Chat.svg',
          color: mutedColor,
          label: _formatCount(commentCount),
          onTap: onCommentTap,
        ),
        const Spacer(),
        _ActionButton(
          svgAsset: 'assets/svgs/share.svg',
          color: mutedColor,
          label: _formatCount(shareCount),
          onTap: onShareTap,
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
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            svgAsset,
            width: 22.w,
            height: 22.h,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyles.font12semiBold.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
