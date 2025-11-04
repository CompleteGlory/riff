import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/features/auth/forgot_password/UI/enter_code_screen.dart';
import 'package:riff/features/auth/forgot_password/UI/forgot_password_screen.dart';
import 'package:riff/features/auth/forgot_password/UI/reset_password_screen.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';
import 'package:riff/features/home/core/UI/home_layout.dart';
import 'package:riff/features/auth/login/UI/login_screen.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'package:riff/features/auth/onboarding/onboarding_screen.dart';
import 'package:riff/features/auth/signup/UI/signup_screen.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_cubit.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';

class AppRouter {
  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.onBoarding:
        return MaterialPageRoute(builder: (_) => const OnBoardingScreen());
      case Routes.login:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => getIt<LoginCubit>(),
            child: const LoginScreen(),
          ),
        );
      case Routes.home:
        return MaterialPageRoute(builder: (_) => BlocProvider(
              create: (context) => getIt<HomeCubit>(),
              child: const HomeLayout(),
            ));
      case Routes.signup:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => getIt<SignupCubit>(),
            child: const SignupScreen(),
          ),
        );
      case Routes.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => getIt<ForgotPasswordCubit>(),
            child: const ForgotPasswordScreen(),
          ),
        );
        case Routes.enterCode:
          return MaterialPageRoute(
            builder: (context) {
              final args = settings.arguments as String?;
              return BlocProvider(
                create: (context) => getIt<ForgotPasswordCubit>(),
                child: EnterCodeScreen(email: args),
              );
            },
          );
      case Routes.resetPassword:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => getIt<ForgotPasswordCubit>(),
            child: const ResetPasswordScreen(),
          ),
        );

      default:
        null;
    }
    return null;
  }
}
