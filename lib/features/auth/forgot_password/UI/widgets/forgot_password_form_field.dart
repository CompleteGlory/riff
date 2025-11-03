import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/app_regex.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/tff.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';

class ForgotPasswordFormField extends StatelessWidget {
  const ForgotPasswordFormField({super.key});

  @override
  Widget build(BuildContext context) {
    final forgotPasswordCubit = context.read<ForgotPasswordCubit>();

    return Form(
      key: forgotPasswordCubit.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Email", style: TextStyles.font15semiBold),
          verticalSpace(4),
          AppTextField(
            controller: forgotPasswordCubit.mailController,
            keyboardType: TextInputType.emailAddress,
            isPassword: false,
            validator: (value) {
              if (value == null ||
                  value.isEmpty ||
                  !AppRegex.isEmailValid(value)) {
                return 'Please enter a valid email address';
              }
            },
            hintText: "Enter your email address",
          ),
          
        ],
      ),
    );
  }
}
