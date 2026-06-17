import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/add_post/logic/cubit/update_post_cubit.dart';
import 'package:riff/features/home/add_post/logic/cubit/update_post_state.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_cubit.dart';
import 'package:riff/generated/l10n.dart';


class UpdatePostListener extends StatelessWidget {

  final Widget child;

  const UpdatePostListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<UpdatePostCubit, UpdatePostState>(
      // Listen to all state changes in the UpdatePostCubit
      listener: (context, state) {
        state.whenOrNull(
          // Handle the loading state by showing a dialog
          loading: () {
            // Show loading dialog, preventing user interaction
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>  Center(
                child: CircularProgressIndicator(
                  color: ColorManager.primaryBlack,
                ),
              ),
            );
          },
          // Handle success state
          success: (post) {
            // 1. Pop the loading dialog
            Navigator.pop(context); 
            
            // 2. Show a success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(backgroundColor: ColorManager.primaryBlack,content: Text(S.of(context).postUpdatedSuccessfully,style: TextStyles.font12Medium.copyWith(color: ColorManager.lighterGrey),),),
            );
            
            // 3. Pop the update screen
            Navigator.pop(context);
            
            // 4. Refresh the feed to show updated post
            try {
              getIt<FeedCubit>().getPosts(refresh: true);
            } catch (_) {
              // If cubits are not available in context for some reason, ignore.
            }
          },
          // Handle failure state
          failure: (error) {
            // 1. Pop the loading dialog (if it was showing)
            Navigator.pop(context); 

            // 2. Show an error message
            final errorMessage = error.errors?[0].message ?? S.of(context).failedToUpdatePost;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(backgroundColor: ColorManager.primaryBlack,content: Text(errorMessage,style: TextStyles.font12Medium.copyWith(color: ColorManager.lighterGrey),)),
            );
          },
        );
      },
      child: child,
    );
  }
}
