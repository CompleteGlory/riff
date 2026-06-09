import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/helpers/time_ago.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_options.dart';

class PostHeader extends StatelessWidget {
  final Post post;
  final VoidCallback onMoreTapped;

  const PostHeader({super.key, required this.post, required this.onMoreTapped});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: ColorManager.lighterGrey,
          backgroundImage: post.author?.profileImageUrl != null
              ? NetworkImage(
                  '${ApiConstants.apiBASEURL}${post.author!.profileImageUrl}',
                )
              : null,
        ),
        horizontalSpace(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.author?.fullName ?? "Unknown",
              style: TextStyles.font15semiBold,
            ),
            Text(
              timeAgo(post.createdAt),
              style: TextStyles.font12regular.copyWith(
                color: ColorManager.normalGrey,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () async {
            final currentUserId =
                await SharedPrefHelper.getString(SharedPrefKeys.userId) ?? "";
            final isMine = post.author?.id == currentUserId;

            if (context.mounted) {
              showPostOptions(isMine: isMine, context: context, post: post);
            }
          },
        ),
      ],
    );
  }
}
