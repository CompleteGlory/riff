import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/tff.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'package:riff/generated/l10n.dart';

class LoginFormFields extends StatelessWidget {
  const LoginFormFields({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final loginCubit = context.read<LoginCubit>();

    return Form(
      key: loginCubit.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.emailOrUsername, style: TextStyles.font15semiBold),
          verticalSpace(4),
          AppTextField(
            controller: loginCubit.mailController,
            keyboardType: TextInputType.emailAddress,
            isPassword: false,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return s.thisFieldIsRequired;
              }
              return null;
            },
            hintText: s.enterEmailOrUsername,
          ),
          verticalSpace(10),
          Text(s.passwordLabel, style: TextStyles.font15semiBold),
          verticalSpace(4),
          AppTextField(
            controller: loginCubit.passwordController,
            keyboardType: TextInputType.visiblePassword,
            isPassword: true,
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return s.passwordIsRequired;
              }
              return null;
            },
            hintText: s.enterYourPassword,
          ),
        ],
      ),
    );
  }
}
