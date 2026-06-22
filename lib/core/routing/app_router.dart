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
import 'package:riff/features/home/add_post/logic/cubit/create_post_cubit.dart';
import 'package:riff/features/home/chat/UI/chats_list_screen.dart';
import 'package:riff/features/home/chat/UI/chat_detail_screen.dart';
import 'package:riff/features/home/chat/UI/create_group_screen.dart';
import 'package:riff/features/home/chat/logic/cubit/chats_list_cubit.dart';
import 'package:riff/features/home/chat/logic/cubit/chat_cubit.dart';
import 'package:riff/features/home/block/UI/blocked_users_screen.dart';
import 'package:riff/features/home/block/logic/cubit/block_cubit.dart';
import 'package:riff/features/home/profile_settings/UI/profile_settings_screen.dart';
import 'package:riff/features/home/profile_settings/logic/profile_settings_cubit.dart';
import 'package:riff/features/legal/privacy_policy_gate_screen.dart';
import 'package:riff/features/legal/privacy_policy_screen.dart';
import 'package:riff/features/home/about/about_us_screen.dart';
import 'package:riff/features/home/account_settings/UI/account_settings_screen.dart';
import 'package:riff/features/home/account_settings/UI/change_password_screen.dart';
import 'package:riff/features/home/account_settings/logic/change_password_cubit.dart';

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
              // Use .value so BlocProvider never calls close() on the singleton.
              // close() is permanent — a closed cubit can never emit again, which
              // caused the chat list to be empty after switching accounts.
              // load() is called in HomeLayout.initState() instead.
              BlocProvider.value(value: getIt<ChatsListCubit>()),
              // Singleton: keeps the cubit alive while a video upload runs in
              // the background after the user navigates away from CreatePostScreen.
              BlocProvider.value(value: getIt<CreatePostCubit>()),
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
        // args may be a callback for post-auth contexts:
        //   Navigator.pushNamed(context, Routes.instruments,
        //     arguments: (List<String> i, List<String> g) { ... });
        final onFinish = settings.arguments
            as void Function(List<String>, List<String>)?;
        return MaterialPageRoute(
          builder: (_) => InstrumentsScreen(onFinish: onFinish),
        );

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

      case Routes.chatsList:
        // Use .value — the singleton is already loaded from HomeLayout
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<ChatsListCubit>(),
            child: const ChatsListScreen(),
          ),
        );

      case Routes.chatDetail:
        final conv = settings.arguments as dynamic; // Conversation
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: getIt<ChatsListCubit>()),
              BlocProvider(create: (_) => getIt<ChatCubit>()),
            ],
            child: ChatDetailScreen(conversation: conv),
          ),
        );

      case Routes.createGroup:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<ChatsListCubit>(),
            child: const CreateGroupScreen(),
          ),
        );

      case Routes.profileSettings:
        // args is a (UserProfile, HomeCubit) record so the screen can
        // refresh the profile instantly after saving.
        final args = settings.arguments as (dynamic, HomeCubit);
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: args.$2), // share existing HomeCubit
              BlocProvider(create: (_) => getIt<ProfileSettingsCubit>()),
            ],
            child: ProfileSettingsScreen(profile: args.$1),
          ),
        );

      case Routes.blockedUsers:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<BlockCubit>(),
            child: const BlockedUsersScreen(),
          ),
        );

      case Routes.privacyPolicy:
        return MaterialPageRoute(
          builder: (_) => const PrivacyPolicyScreen(),
        );

      case Routes.privacyPolicyGate:
        final startAtHome = settings.arguments as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => PrivacyPolicyGateScreen(startAtHome: startAtHome),
        );

      case Routes.aboutUs:
        return MaterialPageRoute(builder: (_) => const AboutUsScreen());

      case Routes.accountSettings:
        final isPrivate = settings.arguments as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => AccountSettingsScreen(initialIsPrivate: isPrivate),
        );

      case Routes.changePassword:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<ChangePasswordCubit>(),
            child: const ChangePasswordScreen(),
          ),
        );

      default:
        return MaterialPageRoute(builder: (_) => const OnBoardingScreen());
    }
  }
}
