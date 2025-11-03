import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/auth/forgot_password/UI/widgets/email_not_recieved_text.dart';
import 'package:riff/features/auth/forgot_password/UI/widgets/enter_code_form_field.dart';
import 'package:riff/features/auth/forgot_password/UI/widgets/request_otp_bloc_listener.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';


class EnterCodeScreen extends StatelessWidget {
  final String? email;

  const EnterCodeScreen({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    // If an email was passed via route args, set it on the cubit so other logic can use it
    final forgotPasswordCubit = context.read<ForgotPasswordCubit>();
    if (email != null && email!.isNotEmpty) {
      forgotPasswordCubit.email = email!;
      // also reflect in controller so UI (if any) is in sync
      forgotPasswordCubit.mailController.text = email!;
    }
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
                        Text("Enter 6 Digit Code", style: TextStyles.font28Bold),
                        verticalSpace(8),
                        Text(
                          "Enter 6 digit code that you've received on your email address.",
                          style: TextStyles.font16Medium.copyWith(color: ColorManager.lightGrey),
                        ),
                        verticalSpace(32),
                        EnterCodeFormField(onCodeCompleted: (String p1) { 
                          context.read<ForgotPasswordCubit>().otp = p1;
                         },),
                        verticalSpace(20),
                        EmailNotRecievedText(),
                        Spacer(),
                        AppButton(onPressed: () {
                          validateAndVerify(context);
                        }, text: "Continue", isWhite: false),
                        verticalSpace(30),
                        const VerifyOTPBlocListener(),
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

  void validateAndVerify(BuildContext context) {
   
    final forgotPasswordCubit = context.read<ForgotPasswordCubit>();
    print(forgotPasswordCubit.email);
    if(forgotPasswordCubit.otp.isNotEmpty && forgotPasswordCubit.email.isNotEmpty) {
      forgotPasswordCubit.emitVerifyOtpState();
    }
  }
}