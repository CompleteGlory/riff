import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/features/auth/forgot_password/UI/enter_code_screen.dart';
import 'package:riff/features/auth/forgot_password/UI/forgot_password_screen.dart';
import 'package:riff/features/auth/forgot_password/UI/reset_password_screen.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';
import 'package:riff/features/auth/user-prefrences/instruments_screen.dart';
import 'package:riff/features/home/core/UI/home_layout.dart';
import 'package:riff/features/auth/login/UI/login_screen.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'package:riff/features/auth/onboarding/onboarding_screen.dart';
import 'package:riff/features/auth/signup/UI/signup_screen.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_cubit.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/notifications/logic/cubit/notifications_cubit.dart';
import 'package:riff/features/auth/phone_verify/UI/phone_verify_screen.dart';
import 'package:riff/features/auth/phone_verify/logic/cubit/phone_verify_cubit.dart';
import 'package:riff/features/auth/new_user_onboarding/UI/new_user_onboarding_screen.dart';

class AppRouter {
  Route<dynamic> generateRoute(RouteSettings settings) {
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
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => getIt<HomeCubit>()),
              BlocProvider(
                create: (_) => getIt<NotificationsCubit>()..load(),
              ),
            ],
            child: const HomeLayout(),
          ),
        );

      case Routes.signup:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => getIt<SignupCubit>()
                  ..selectedInstruments =
                      (args?['instruments'] as List<String>?) ?? const []
                  ..selectedGenres =
                      (args?['genres'] as List<String>?) ?? const [],
              ),
              BlocProvider(create: (_) => getIt<LoginCubit>()),
            ],
            child: const SignupScreen(),
          ),
        );

      case Routes.instruments:
        return MaterialPageRoute(builder: (_) => const InstrumentsScreen());

      case Routes.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => getIt<ForgotPasswordCubit>(),
            child: const ForgotPasswordScreen(),
          ),
        );

      case Routes.enterCode:
        final args = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => getIt<ForgotPasswordCubit>(),
            child: EnterCodeScreen(email: args),
          ),
        );

      case Routes.resetPassword:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => getIt<ForgotPasswordCubit>(),
            child: const ResetPasswordScreen(),
          ),
        );

      case Routes.phoneVerify:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<PhoneVerifyCubit>(),
            child: const PhoneVerifyScreen(),
          ),
        );

      case Routes.newUserOnboarding:
        return MaterialPageRoute(
          builder: (_) => const NewUserOnboardingScreen(),
        );

      default:
        return MaterialPageRoute(builder: (_) => const OnBoardingScreen());
    }
  }
}
