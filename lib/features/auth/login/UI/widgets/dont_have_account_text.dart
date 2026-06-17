import 'package:flutter/material.dart';
import 'package:riff/core/helpers/extenstions.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/generated/l10n.dart';

class DonotHaveAnAccountText extends StatelessWidget {
  const DonotHaveAnAccountText({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(s.dontHaveAnAccount,
            style: TextStyles.font14regular
                .copyWith(color: ColorManager.lightGrey)),
        TextButton(
          onPressed: () => context.pushNamed(Routes.signup),
          child: Text(
            s.joinBtn,
            style: TextStyles.font16Medium.copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
