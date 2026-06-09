import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_state.dart';


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
