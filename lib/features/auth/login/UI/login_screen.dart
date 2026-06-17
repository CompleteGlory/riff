import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/auth/login/UI/widgets/dont_have_account_text.dart';
import 'package:riff/features/auth/login/UI/widgets/forgot_password_text.dart';
import 'package:riff/features/auth/login/UI/widgets/login_bloc_listener.dart';
import 'package:riff/features/auth/login/UI/widgets/login_form_fields.dart';
import 'package:riff/features/auth/login/UI/widgets/or_divider.dart';
import 'package:riff/features/auth/login/UI/widgets/social_login.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'package:riff/generated/l10n.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.loginTitle, style: TextStyles.font28Bold),
                            verticalSpace(8),
                            Text(
                              s.itsGreatToSeeYouAgain,
                              style: TextStyles.font16Medium
                                  .copyWith(color: ColorManager.lightGrey),
                            ),
                            verticalSpace(32),
                            LoginFormFields(),
                            verticalSpace(10),
                            ForgotPasswordText(),
                            verticalSpace(20),
                            AppButton(
                              onPressed: () => validateAndLogin(context),
                              text: s.loginBtn,
                              isWhite: false,
                            ),
                            verticalSpace(15),
                            OrDivider(),
                            verticalSpace(15),
                            SocialLogin(),
                            const Spacer(),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: DonotHaveAnAccountText(),
                            ),
                            verticalSpace(10),
                            const LoginBlocListener(),
                          ],
                        ),
                      ),
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

  void validateAndLogin(BuildContext context) {
    if (context.read<LoginCubit>().formKey.currentState!.validate()) {
      context.read<LoginCubit>().emitLoginStates();
    }
  }
}
