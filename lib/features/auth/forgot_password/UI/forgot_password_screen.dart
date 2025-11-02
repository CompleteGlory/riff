import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/auth/forgot_password/UI/widgets/forgot_password_bloc_listener.dart';
import 'package:riff/features/auth/forgot_password/UI/widgets/forgot_password_form_field.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

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
                        Text("Forgot Password", style: TextStyles.font28Bold),
                        verticalSpace(8),
                        Text(
                          "Enter your email for the verification process. We will send 4 digits code to your email.",
                          style: TextStyles.font16Medium.copyWith(color: ColorManager.lightGrey),
                        ),
                        verticalSpace(32),
                        ForgotPasswordFormField(),
                        verticalSpace(20),
                        AppButton(onPressed: () {
                          validateAndRequestOtp(context);
                        }, text: "Send Code", isWhite: false),
                        verticalSpace(10),
                        const ForgotPasswordBlocListener(),
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

  void validateAndRequestOtp(BuildContext context) {
    final forgotPasswordCubit = context.read<ForgotPasswordCubit>();
    if (forgotPasswordCubit.formKey.currentState!.validate()) {
      forgotPasswordCubit.emitForgotPasswordStates();
    }
  }
}