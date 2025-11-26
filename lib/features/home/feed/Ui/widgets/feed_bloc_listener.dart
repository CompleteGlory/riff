import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/feed/logic/cubit/feed_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/feed_state.dart';


class FeedBlocListener extends StatelessWidget {
  const FeedBlocListener({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<FeedCubit, FeedState>(
      listenWhen: (previous, current) =>
          current is Loading ||
          current is Success ||
          current is Error,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state.whenOrNull(
            loading: () {
              showDialog(
                context: context,
                useRootNavigator: true,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: ColorManager.primaryBlack,
                  ),
                ),
              );
            },
            success: (_) {
              // if (Navigator.of(context, rootNavigator: true).canPop()) {
              //   Navigator.of(context, rootNavigator: true).pop();
              // }
            },
            failure: (error) {
              _setupErrorState(context, error.message.toString());
            },
          );
        });
      },
      child: const SizedBox.shrink(),
    );
  }

  void _setupErrorState(BuildContext context, String error) {
    // if (Navigator.of(context, rootNavigator: true).canPop()) {
    //   Navigator.of(context, rootNavigator: true).pop();
    // }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 32),
        content: Text(
          error,
          textAlign: TextAlign.center,
          style: TextStyles.font14Medium.copyWith(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyles.font14Medium.copyWith(
                color: ColorManager.primaryBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
