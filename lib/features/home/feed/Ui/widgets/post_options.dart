// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/add_post/logic/cubit/update_post_cubit.dart';
import 'package:riff/features/home/add_post/logic/cubit/delete_post_cubit.dart';
import 'package:riff/features/home/add_post/ui/update_post_dialog.dart';
import 'package:riff/features/home/add_post/ui/widgets/delete_post_confirm_dialog.dart';
import 'package:riff/features/home/feed/data/models/post.dart';

void showPostOptions({
  required bool isMine,
  required BuildContext context,
  required Post post,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag indicator
            Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 20.h),

            Text(
              "Post Options",
              style: TextStyles.font18Semibold,
            ),
            SizedBox(height: 20.h),

            if (isMine) ...[
              _optionTile(
                picture: "assets/svgs/edit.svg",
                text: "Edit Post",
                onTap: () {
                  Navigator.pop(context);
                  // Get the cubit from the service locator
                  final updatePostCubit = getIt<UpdatePostCubit>();
                  showDialog(
                    context: context,
                    builder: (context) => UpdatePostDialog(
                      post: post,
                      updatePostCubit: updatePostCubit,
                    ),
                  );
                },
              ),
              _optionTile(
                picture: "assets/svgs/delete.svg",
                text: "Delete Post",
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  // Get the delete cubit from the service locator
                  final deletePostCubit = getIt<DeletePostCubit>();
                  final postId = (post.id).toString();
                  showDialog(
                    context: context,
                    builder: (context) => DeletePostConfirmDialog(
                      postId: postId,
                      deletePostCubit: deletePostCubit,
                    ),
                  );
                },
              ),
            ] else ...[
              _optionTile(
                picture: "assets/svgs/report.svg",
                text: "Report Post",
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: report
                  print("report post");
                },
              ),
            ],

            SizedBox(height: 10.h),
          ],
        ),
      );
    },
  );
}

Widget _optionTile({
  required String picture,
  required String text,
  required VoidCallback onTap,
  Color color = Colors.black,
}) {
  return ListTile(
    leading: SvgPicture.asset(picture, width: 24.w, height: 24.h, color: color),
    title: Text(
      text,
      style: TextStyles.font16Medium.copyWith(color: color),
    ),
    onTap: onTap,
    contentPadding: EdgeInsets.zero,
  );
}
