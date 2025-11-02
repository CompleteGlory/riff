import 'package:flutter/material.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/features/login/UI/login_screen.dart';
import 'package:riff/features/onboarding/onboarding_screen.dart';
import 'package:riff/features/signup/UI/signup_screen.dart';

class AppRouter {
   Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.onBoarding:
        return MaterialPageRoute(
          builder: (_) => const OnBoardingScreen(),
        );
      case Routes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case Routes.signup:
        return MaterialPageRoute(
          builder: (_) => const SignupScreen(),
        );
        default:
        null;
    }
    return null;
  }
}