import 'package:flutter/material.dart';
import 'package:riff/core/routing/routes.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void navigateToLoginAndClearStack() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }
}
