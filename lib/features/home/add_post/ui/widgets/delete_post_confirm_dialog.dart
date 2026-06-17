import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/home/add_post/logic/cubit/delete_post_cubit.dart';
import 'package:riff/features/home/add_post/logic/cubit/delete_post_state.dart';
import 'package:riff/generated/l10n.dart';

class DeletePostConfirmDialog extends StatelessWidget {
  final String postId;
  final DeletePostCubit deletePostCubit;

  const DeletePostConfirmDialog({
    super.key,
    required this.postId,
    required this.deletePostCubit,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return BlocProvider.value(
      value: deletePostCubit,
      child: BlocListener<DeletePostCubit, DeletePostState>(
        listener: (context, state) {
          state.whenOrNull(
            loading: () {
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(
                    color: ColorManager.primaryBlack,
                  ),
                ),
              );
            },
            success: () {
              // Pop loading dialog
              Navigator.pop(context);
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: ColorManager.primaryBlack,
                  content: Text(
                    s.postDeletedSuccessfully,
                    style: TextStyles.font12Medium.copyWith(
                      color: ColorManager.lighterGrey,
                    ),
                  ),
                ),
              );
              Navigator.pop(context);
            },
            failure: (error) {
              // Pop loading dialog
              Navigator.pop(context);
              
              // Show error message
              final errorMessage = error.errors?[0].message ?? "Failed to delete post.";
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: ColorManager.primaryBlack,
                  content: Text(
                    errorMessage,
                    style: TextStyles.font12Medium.copyWith(
                      color: ColorManager.lighterGrey,
                    ),
                  ),
                ),
              );
            },
          );
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.deletePostDialogTitle,
                  style: TextStyles.font28Bold.copyWith(
                    color: ColorManager.primaryBlack,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  s.deletePostDialogContent,
                  style: TextStyles.font14regular.copyWith(
                    color: ColorManager.normalGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        onPressed: () => Navigator.pop(context),
                        text: s.cancelBtn,
                        isWhite: true,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: AppButton(
                        onPressed: () {
                          deletePostCubit.deletePost(postId);
                        },
                        text: s.deleteBtn,
                        isWhite: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
