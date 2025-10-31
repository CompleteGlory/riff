import 'package:flutter/material.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/features/onboarding/onboarding_screen.dart';

class AppRouter {
   Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.onBoarding:
        return MaterialPageRoute(
          builder: (_) => const OnBoardingScreen(),
        );
        default:
        null;
    }
    return null;
  }
}