import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/extenstions.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_state.dart';

class ResetPasswordBlocListener extends StatelessWidget {
  const ResetPasswordBlocListener({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
      listenWhen: (previous, current) =>
          current is ResetPasswordLoading ||
          current is ResetPasswordSuccess ||
          current is ResetPasswordFailed,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state.whenOrNull(
            resetPasswordLoading: () {
              // show loading dialog on root navigator so it can be popped reliably
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
            resetPasswordSuccess: (message) async {
              // dismiss loading dialog if present on root navigator
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              }
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/green-check.png',
                        width: 80.w,
                        height: 80.h,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Success!',
                        textAlign: TextAlign.center,
                        style: TextStyles.font18Semibold,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Password updated successfully.\nPlease login to continue.',
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
            },
            resetPasswordFailed: (error) {
              _setupErrorState(context, error.message!);
            },
          );
        });
      },
      child: const SizedBox.shrink(),
    );
  }

  void _setupErrorState(BuildContext context, String error) {
    // Dismiss loading dialog if present (on root navigator) without popping page route
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
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
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Try Again',
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
