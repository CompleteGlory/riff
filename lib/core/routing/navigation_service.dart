import 'package:flutter/material.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/features/home/notifications/logic/cubit/notifications_cubit.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void navigateToLoginAndClearStack() {
    // Reset notifications so the next user starts clean.
    try { getIt<NotificationsCubit>().reset(); } catch (_) {}
    navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }
}
