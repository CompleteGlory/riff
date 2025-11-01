import 'package:flutter/material.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';

class ForgotPasswordText extends StatelessWidget {
  const ForgotPasswordText({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text("Forgot your Password?", style: TextStyles.font14regular.copyWith(color: ColorManager.lightGrey)),
        TextButton(
          onPressed: () {},
          child: Text(
            "Reset your password",
            style: TextStyles.font16Medium.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
