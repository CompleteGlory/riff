import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/tff.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';

class ResetPasswordFormFields extends StatelessWidget {
  const ResetPasswordFormFields({super.key});

  @override
  Widget build(BuildContext context) {
    final forgotPasswordCubit = context.read<ForgotPasswordCubit>();

    return Form(
      key: forgotPasswordCubit.resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("New Password", style: TextStyles.font15semiBold),
          verticalSpace(4),
          AppTextField(
            controller: forgotPasswordCubit.newPasswordController,
            keyboardType: TextInputType.visiblePassword,
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
            hintText: "Enter your new password",
          ),
          verticalSpace(16),
          Text("Confirm New Password", style: TextStyles.font15semiBold),
          verticalSpace(4),
          AppTextField(
            controller: forgotPasswordCubit.confirmPasswordController,
            keyboardType: TextInputType.visiblePassword,
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != forgotPasswordCubit.newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            hintText: "Confirm your new password",
          ),
        ],
      ),
    );
  }
}