import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'google_sign_in_helper.dart';

class SocialLogin extends StatelessWidget {
  const SocialLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final token = await GoogleSignInHelper.signInAndGetIdToken();

        if (token == null) {
          debugPrint("Google: Failed to get ID token");
          return;
        }

        debugPrint("Google ID TOKEN = $token");
        // ignore: use_build_context_synchronously
        context.read<LoginCubit>().loginWithGoogle(token);
      },
      child: SvgPicture.asset("assets/svgs/google_button.svg"),
    );
  }
}
