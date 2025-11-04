import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:riff/core/helpers/spacing.dart';

class SocialLogin extends StatelessWidget {
  const SocialLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        verticalSpace(15),
        GestureDetector(
          onTap: () {},
          child: SvgPicture.asset("assets/svgs/google_button.svg"),
        ),
        verticalSpace(15),
        GestureDetector(
          onTap: () {},
          child: SvgPicture.asset("assets/svgs/facebook_button.svg"),
        ),
      ],
    );
  }
}
