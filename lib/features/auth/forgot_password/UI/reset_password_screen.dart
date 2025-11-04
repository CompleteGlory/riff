import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';
import 'package:riff/features/auth/forgot_password/UI/widgets/reset_password_form_fields.dart';
import 'package:riff/features/auth/forgot_password/UI/widgets/reset_password_bloc_listener.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  void validateAndResetPassword(BuildContext context) {
    final forgotPasswordCubit = context.read<ForgotPasswordCubit>();
    if (forgotPasswordCubit.resetFormKey.currentState!.validate()) {
      forgotPasswordCubit.emitResetPasswordState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Reset Password", style: TextStyles.font28Bold),
                        verticalSpace(8),
                        Text(
                          "Set the new password for your account so you can login and access all the features.",
                          style: TextStyles.font16Medium.copyWith(color: ColorManager.lightGrey),
                        ),
                        verticalSpace(32),
                        const ResetPasswordFormFields(),
                        const Spacer(),
                        AppButton(
                          onPressed: () {
                            validateAndResetPassword(context);
                          },
                          text: "Reset Password",
                          isWhite: false
                        ),
                        verticalSpace(30),
                        const ResetPasswordBlocListener(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}