import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/app_regex.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/tff.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';

class LoginFormFields extends StatelessWidget {
  const LoginFormFields({super.key});

  @override
  Widget build(BuildContext context) {
    final loginCubit = context.read<LoginCubit>();

    return Form(
      key: loginCubit.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Email", style: TextStyles.font15semiBold),
          verticalSpace(4),
          AppTextField(
            controller: loginCubit.mailController,
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
          verticalSpace(10),
          Text("Password", style: TextStyles.font15semiBold),
          verticalSpace(4),
          AppTextField(
            controller: loginCubit.passwordController,
            keyboardType: TextInputType.visiblePassword,
            isPassword: true,
            validator: (String? value) {
               if (value == null || value.isEmpty) {
                return 'Password is required';
              }else if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
            hintText: "Enter your password",
          ),
        ],
      ),
    );
  }
}
