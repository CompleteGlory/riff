import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/features/home/UI/home_screen.dart';
import 'package:riff/features/login/UI/login_screen.dart';
import 'package:riff/features/login/logic/cubit/login_cubit.dart';
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
          builder: (_) => BlocProvider(
            create: (context) => getIt<LoginCubit>(),
            child: const LoginScreen(),
          ),
        );
      case Routes.home:
         return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
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