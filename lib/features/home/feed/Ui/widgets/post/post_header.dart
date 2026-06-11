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
    final imageUrl = post.author?.profileImageUrl;
    final fullUrl = imageUrl != null && imageUrl.isNotEmpty
        ? (imageUrl.startsWith('http')
            ? imageUrl
            : '${ApiConstants.apiBASEURL}$imageUrl')
        : null;

    final initials = (post.author?.fullName ?? 'U')
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();

    return Row(
      children: [
        // Avatar
        Container(
          width: 42.r,
          height: 42.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorManager.lighterGrey,
          ),
          child: ClipOval(
            child: fullUrl != null
                ? Image.network(
                    fullUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _Initials(initials),
                  )
                : _Initials(initials),
          ),
        ),
        horizontalSpace(10),

        // Name + time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.author?.fullName ?? 'Unknown',
                style: TextStyles.font15semiBold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                timeAgo(post.createdAt),
                style: TextStyles.font12regular.copyWith(
                  color: ColorManager.normalGrey,
                ),
              ),
            ],
          ),
        ),

        // More button
        GestureDetector(
          onTap: () async {
            final currentUserId =
                await SharedPrefHelper.getString(SharedPrefKeys.userId) ?? '';
            final isMine = post.author?.id == currentUserId;
            if (context.mounted) {
              showPostOptions(isMine: isMine, context: context, post: post);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(4.r),
            child: Icon(
              Icons.more_horiz,
              color: ColorManager.normalGrey,
              size: 22.r,
            ),
          ),
        ),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: ColorManager.normalGrey,
        ),
      ),
    );
  }
}
