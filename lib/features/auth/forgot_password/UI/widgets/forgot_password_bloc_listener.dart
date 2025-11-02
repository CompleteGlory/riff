import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_state.dart';


class ForgotPasswordBlocListener extends StatelessWidget {
  const ForgotPasswordBlocListener({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
      listenWhen: (previous, current) =>
          current is Loading || current is Success || current is Error,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state.whenOrNull(
            loading: () {
              showDialog(
                context: context,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: ColorManager.primaryBlack,
                  ),
                ),
              );
            },
            success: (forgotPasswordResponse) {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed(Routes.enterCode);
            },
            failure: (error) {
              _setupErrorState(context, error.message!);
            },
          );
        });
      },
      child: const SizedBox.shrink(),
    );
  }

  void _setupErrorState(BuildContext context, String error) {
  Navigator.of(context).pop();
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
            style: TextStyles.font14Medium.copyWith(color: ColorManager.primaryBlack),
          ),
        ),
      ],
    ),
  );
}
}