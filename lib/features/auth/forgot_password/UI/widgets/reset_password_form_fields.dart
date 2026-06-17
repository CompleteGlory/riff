import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/tff.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';
import 'package:riff/generated/l10n.dart';

class ResetPasswordFormFields extends StatelessWidget {
  const ResetPasswordFormFields({super.key});

  @override
  Widget build(BuildContext context) {
    final forgotPasswordCubit = context.read<ForgotPasswordCubit>();
    final s = S.of(context);

    return Form(
      key: forgotPasswordCubit.resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.passwordLabel, style: TextStyles.font15semiBold),
          verticalSpace(4),
          AppTextField(
            controller: forgotPasswordCubit.newPasswordController,
            keyboardType: TextInputType.visiblePassword,
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return s.pleaseEnterPassword;
              }
              if (value.length < 8) {
                return s.passwordMinLength;
              }
              return null;
            },
            hintText: s.enterNewPassword,
          ),
          verticalSpace(16),
          Text(s.passwordLabel, style: TextStyles.font15semiBold),
          verticalSpace(4),
          AppTextField(
            controller: forgotPasswordCubit.confirmPasswordController,
            keyboardType: TextInputType.visiblePassword,
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return s.pleaseConfirmPassword;
              }
              if (value != forgotPasswordCubit.newPasswordController.text) {
                return s.passwordsDoNotMatch;
              }
              return null;
            },
            hintText: s.confirmNewPassword,
          ),
        ],
      ),
    );
  }
}