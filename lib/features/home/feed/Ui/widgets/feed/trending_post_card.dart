import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/Ui/post_detail_screen.dart';
import 'package:riff/core/routing/animated_page_route.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_header.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_content.dart';

/// A card that surfaces the most-viewed post from the last 3 days.
/// Styled with an accent border and 🔥 "Trending" badge.
class TrendingPostCard extends StatelessWidget {
  final Post post;

  const TrendingPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return GestureDetector(
      onTap: () {
        HomeCubit? homeCubit;
        try { homeCubit = context.read<HomeCubit>(); } catch (_) {}
        Navigator.push(
          context,
          FadeSlidePageRoute(
            page: homeCubit != null
                ? BlocProvider.value(
                    value: homeCubit,
                    child: PostDetailScreen(post: post),
                  )
                : PostDetailScreen(post: post),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: ColorManager.accent, width: 2),
          boxShadow: [
            BoxShadow(
              color: ColorManager.accent.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Trending badge row ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 0),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: ColorManager.accent,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4.w),
                        Text(
                          'Trending',
                          style: TextStyles.font12semiBold.copyWith(
                            color: ColorManager.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.visibility_outlined,
                    size: 14.w,
                    color: ColorManager.normalGrey,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatCount(post.viewsCount ?? 0),
                    style: TextStyles.font12semiBold
                        .copyWith(color: ColorManager.normalGrey),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.h),

            // ── Post header ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 8.w, 10.h),
              child: PostHeader(post: post, onMoreTapped: () {}),
            ),

            // ── Post content ────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: PostContent(
                post: post,
                showHeartAnimation: false,
                onVideoTap: (_) {},
              ),
            ),

            SizedBox(height: 14.h),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}
