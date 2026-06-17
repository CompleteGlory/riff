import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/add_post/logic/cubit/create_post_cubit.dart';
import 'package:riff/features/home/add_post/logic/cubit/create_post_state.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/generated/l10n.dart';


class AddPostListener extends StatelessWidget {

  const AddPostListener({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreatePostCubit, CreatePostState>(
      // Listen to all state changes in the CreatePostCubit
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
              SnackBar(backgroundColor: ColorManager.primaryBlack,content: Text(S.of(context).postCreatedSuccessfully,style: TextStyles.font12Medium.copyWith(color: ColorManager.lighterGrey),),),
            );
            
            // 3. Switch to Feed tab so the user sees their new post
            try {
              context.read<HomeCubit>().changeScreen(0);
            } catch (_) {
              // If HomeCubit is not available in context for some reason, ignore.
            }
          },
          // Handle failure state
          failure: (error) {
            // 1. Pop the loading dialog (if it was showing)
            Navigator.pop(context); 

            // 2. Show an error message
            final errorMessage = error.errors?[0].message ?? S.of(context).failedToCreatePost;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(backgroundColor: ColorManager.primaryBlack,content: Text(errorMessage,style: TextStyles.font12Medium.copyWith(color: ColorManager.lighterGrey),)),
            );
          },
        );
      },
      child: const SizedBox.shrink(), // This widget does not render anything
    );
  }
}