// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/add_post/logic/cubit/update_post_cubit.dart';
import 'package:riff/features/home/add_post/logic/cubit/delete_post_cubit.dart';
import 'package:riff/features/home/add_post/ui/widgets/delete_post_confirm_dialog.dart';
import 'package:riff/features/home/add_post/ui/widgets/update_post_listener.dart';
import 'package:riff/features/home/add_post/ui/widgets/update_post_screen.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/Ui/screens/report_post_screen.dart';

void showPostOptions({
  required bool isMine,
  required BuildContext context,
  required Post post,
}) {
  final onSurface = Theme.of(context).colorScheme.onSurface;
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
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
                color: Theme.of(sheetCtx).dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 20.h),

            Text('Post Options', style: TextStyles.font18Semibold),
            SizedBox(height: 20.h),

            if (isMine) ...[
              _optionTile(
                picture: 'assets/svgs/edit.svg',
                text: 'Edit Post',
                color: onSurface,
                onTap: () {
                  // Close the bottom sheet first, then push the edit screen.
                  Navigator.pop(sheetCtx);
                  final cubit = getIt<UpdatePostCubit>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: UpdatePostListener(
                          child: UpdatePostScreen(post: post),
                        ),
                      ),
                    ),
                  );
                },
              ),
              _optionTile(
                picture: 'assets/svgs/delete.svg',
                text: 'Delete Post',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  final deletePostCubit = getIt<DeletePostCubit>();
                  final postId = post.id.toString();
                  showDialog(
                    context: context,
                    builder: (_) => DeletePostConfirmDialog(
                      postId: postId,
                      deletePostCubit: deletePostCubit,
                    ),
                  );
                },
              ),
            ] else ...[
              _optionTile(
                picture: 'assets/svgs/report.svg',
                text: 'Report Post',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportPostScreen(postId: post.id.toString()),
                    ),
                  );
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
    title: Text(text, style: TextStyles.font16Medium.copyWith(color: color)),
    onTap: onTap,
    contentPadding: EdgeInsets.zero,
  );
}
