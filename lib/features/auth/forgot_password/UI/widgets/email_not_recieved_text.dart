import 'package:flutter/material.dart';
import 'package:riff/core/helpers/extenstions.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';

class EmailNotRecievedText extends StatelessWidget {
  const EmailNotRecievedText({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Email not recieved ?", style: TextStyles.font14regular.copyWith(color: ColorManager.lightGrey)),
        TextButton(
          onPressed: () {
            context.pushNamed(Routes.forgotPassword);
          },
          child: Text(
            "Resend code",
            style: TextStyles.font16Medium.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}