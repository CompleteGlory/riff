import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/app_regex.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/tff.dart';
import 'package:riff/features/signup/logic/cubit/signup_cubit.dart';

class SignUpFormFields extends StatelessWidget {
  const SignUpFormFields({super.key});

  @override
  Widget build(BuildContext context) {
    final signupCubit = context.read<SignupCubit>();
    return Form(
      key: signupCubit.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Full Name", style: TextStyles.font15semiBold),
          verticalSpace(4),
          AppTextField(
            controller: signupCubit.fullNameController,
            keyboardType: TextInputType.name,
            isPassword: false,
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return "This field is required";
              }
              return null;
            },
            hintText: "Enter your full name",
          ),
          verticalSpace(10),
          Text("UserName", style: TextStyles.font15semiBold),
          verticalSpace(4),
          AppTextField(
            controller: signupCubit.usernameController,
            keyboardType: TextInputType.name,
            isPassword: false,
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return "This field is required";
              }
              return null;
            },
            hintText: "Enter your user name",
          ),
          verticalSpace(10),
          Text("Email", style: TextStyles.font15semiBold),
          verticalSpace(4),
          AppTextField(
            controller: signupCubit.mailController,
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
            controller: signupCubit.passwordController,
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
