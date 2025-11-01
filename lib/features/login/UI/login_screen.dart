import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/login/UI/widgets/dont_have_account_text.dart';

import 'package:riff/features/login/UI/widgets/forgot_password_text.dart';
import 'package:riff/features/login/UI/widgets/login_form_fields.dart';
import 'package:riff/features/login/UI/widgets/or_divider.dart';
import 'package:riff/features/login/UI/widgets/social_login.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Login To your account", style: TextStyles.font28Bold),
                verticalSpace(8),
                Text(
                  "It's great to see you again!",
                  style: TextStyles.font16Medium.copyWith(color: ColorManager.lightGrey),
                ),
                verticalSpace(32),
                LoginFormFields(),
                verticalSpace(10),
                ForgotPasswordText(),
                verticalSpace(20),
                AppButton(onPressed: () {}, text: "Login", isWhite: true),
                verticalSpace(15),
                OrDivider(),
                SocialLogin(),
                verticalSpace(125),
                DonotHaveAnAccountText(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
