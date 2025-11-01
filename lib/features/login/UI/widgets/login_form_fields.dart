import 'package:flutter/material.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/tff.dart';

class LoginFormFields extends StatelessWidget {
  const LoginFormFields({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Email", style: TextStyles.font15semiBold),
        verticalSpace(4),
        AppTextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          isPassword: false,
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return "This field is required";
            }
            return null;
          },
          hintText: "Enter your email address",
        ),
        verticalSpace(10),
        Text("Password", style: TextStyles.font15semiBold),
        verticalSpace(4),
        AppTextField(
          controller: controller,
          keyboardType: TextInputType.visiblePassword,
          isPassword: true,
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return "This field is required";
            }
            return null;
          },
          hintText: "Enter your password",
        ),
      ],
    );
  }
}
