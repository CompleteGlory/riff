import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/extenstions.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_cubit.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_state.dart';

class SignupBlocListener extends StatelessWidget {
  const SignupBlocListener({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignupCubit, SignupState>(
      listenWhen: (previous, current) =>
          current is Loading || current is Success || current is Error,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state.whenOrNull(
            loading: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: ColorManager.primaryBlack,
                  ),
                ),
              );
            },
            success: (signupResponse) {
              Navigator.of(context).pop(); // Close loading dialog
              _setupSuccessState(context);
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

  void _setupSuccessState(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/green-check.png',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Success!',
              textAlign: TextAlign.center,
              style: TextStyles.font18Semibold,
            ),
            const SizedBox(height: 8),
            Text(
              'User registered successfully.\nPlease login to continue.',
              textAlign: TextAlign.center,
              style: TextStyles.font14Medium.copyWith(
                color: ColorManager.lightGrey,
              ),
            ),
          ],
        ),
        actions: [
          AppButton(
            text: 'Proceed to Login',
            onPressed: () {
              Navigator.of(context).pop(); // Close success dialog
              context.pushNamed(Routes.login);
            },
            isWhite: false,
          ),
        ],
      ),
    );
  }

  void _setupErrorState(BuildContext context, String error) {
    Navigator.of(context).pop(); // Close loading dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.error,
          color: Colors.red,
          size: 32,
        ),
        content: Text(
          error,
          textAlign: TextAlign.center,
          style: TextStyles.font14Medium.copyWith(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
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