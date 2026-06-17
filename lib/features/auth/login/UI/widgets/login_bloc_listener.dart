import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/services/push_notification_service.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'package:riff/features/auth/login/logic/cubit/login_state.dart';
import 'package:riff/generated/l10n.dart';

class LoginBlocListener extends StatelessWidget {
  const LoginBlocListener({super.key, this.isSignupFlow = false});

  /// When true, shows an "already linked" dialog if the Google account
  /// already existed (i.e. the user tried to sign UP with an existing Gmail).
  final bool isSignupFlow;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (previous, current) =>
          current is Loading || current is Success || current is Error,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state.whenOrNull(
            loading: () {
              // show loading dialog on root navigator so it can be popped reliably
              showDialog(
                context: context,
                useRootNavigator: true,
                barrierDismissible: false,
                builder: (context) =>  Center(
                  child: CircularProgressIndicator(
                    color: ColorManager.primaryBlack,
                  ),
                ),
              );
            },
            success: (loginResponse) async {
              // dismiss loading dialog if present on root navigator
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              }

              // If we're on the signup screen and the Gmail already had an account,
              // show an informational dialog before navigating.
              final resp = loginResponse as LoginResponse?;
              if (isSignupFlow && resp != null && !resp.isNewUser) {
                final s = S.of(context);
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    icon: const Icon(
                      Icons.account_circle_rounded,
                      color: Color(0xFF4285F4),
                      size: 36,
                    ),
                    title: Text(
                      s.gmailAlreadyLinkedTitle,
                      textAlign: TextAlign.center,
                      style: TextStyles.font15semiBold
                          .copyWith(color: const Color(0xFF4285F4)),
                    ),
                    content: Text(
                      s.gmailAlreadyLinked,
                      textAlign: TextAlign.center,
                      style: TextStyles.font14Medium,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          s.gotItBtn,
                          style: TextStyles.font14Medium.copyWith(
                            color: ColorManager.primaryBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Register FCM token now that the user is authenticated
              PushNotificationService.instance.init();
              // Clear the navigation stack and go to Home so user cannot go back
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.home,
                  (route) => false,
                );
              }
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
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    final s = S.of(context);
    final isGoogleAccount = error.toLowerCase().contains('google') ||
        error.toLowerCase().contains('linked to a');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: isGoogleAccount
            ? const Icon(Icons.account_circle_rounded, color: Color(0xFF4285F4), size: 36)
            : const Icon(Icons.error, color: Colors.red, size: 32),
        title: isGoogleAccount
            ? Text(
                'Google Account',
                textAlign: TextAlign.center,
                style: TextStyles.font15semiBold.copyWith(color: const Color(0xFF4285F4)),
              )
            : null,
        content: Text(
          isGoogleAccount ? s.linkedToGoogleAccount : error,
          textAlign: TextAlign.center,
          style: TextStyles.font14Medium.copyWith(
            color: isGoogleAccount ? Colors.black87 : Colors.red,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              s.gotItBtn,
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
