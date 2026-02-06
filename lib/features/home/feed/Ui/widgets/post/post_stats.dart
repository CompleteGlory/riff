import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/themes/colors/color_manager.dart';

class PostStats extends StatelessWidget {
  final int likeCount;

  const PostStats({
    super.key,
    required this.likeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 33.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$likeCount likes',
            style: TextStyles.font14semiBold.copyWith(
              color: ColorManager.darkGrey,
            ),
          ),
          verticalSpace(4),
        ],
      ),
    );
  }
}
