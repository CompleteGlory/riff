import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_state.dart';

class VerifyOTPBlocListener extends StatelessWidget {
  const VerifyOTPBlocListener({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
      listenWhen: (previous, current) =>
          current is OtpVerificationLoading ||
          current is OtpVerified ||
          current is OtpVerificationFailed,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state.whenOrNull(
            otpVerificationLoading: () {
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
            otpVerified: (forgotPasswordResponse) async {
              // attempt to dismiss loading dialog only on root navigator
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              }
              Navigator.of(context).pushReplacementNamed(Routes.resetPassword);
            },
            otpVerificationFailed: (error) {
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
