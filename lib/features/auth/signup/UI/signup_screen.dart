import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/auth/login/UI/widgets/or_divider.dart';
import 'package:riff/features/auth/login/UI/widgets/social_login.dart';
import 'package:riff/features/auth/signup/UI/widgets/already_have_account_text.dart';
import 'package:riff/features/auth/signup/UI/widgets/signup_bloc_listener.dart';
import 'package:riff/features/auth/signup/UI/widgets/signup_form_fields.dart';
import 'package:riff/features/auth/signup/UI/widgets/terms_and_conditions_text.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_cubit.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Create an account", style: TextStyles.font28Bold),
                        verticalSpace(8),
                        Text(
                          "let's create you account.",
                          style: TextStyles.font16Medium.copyWith(
                            color: ColorManager.lightGrey,
                          ),
                        ),
                        verticalSpace(32),
                        SignUpFormFields(),
                        verticalSpace(10),
                        TermsAndConditionsText(),
                        verticalSpace(20),
                        AppButton(
                          onPressed: () {
                            validateAndSignup(context);
                          },
                          text: "Create An Account",
                          isWhite: false,
                        ),
                        verticalSpace(15),
                        OrDivider(),
                        SocialLogin(),
                        Spacer(),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: AlreadyHaveAnAccountText(),
                        ),
                        verticalSpace(10),
                        SignupBlocListener(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void validateAndSignup(BuildContext context) {
    if (context.read<SignupCubit>().formKey.currentState!.validate()) {
      context.read<SignupCubit>().emitSignupStates();
    }
  }
}
