import 'package:flutter/material.dart';
import 'package:riff/core/helpers/extenstions.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/generated/l10n.dart';

class ForgotPasswordText extends StatelessWidget {
  const ForgotPasswordText({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      children: [
        Text(s.forgotYourPassword,
            style: TextStyles.font12regular
                .copyWith(color: ColorManager.lightGrey)),
        TextButton(
          onPressed: () => context.pushNamed(Routes.forgotPassword),
          child: Text(
            s.resetYourPassword,
            style: TextStyles.font16Medium.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
