import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riff/core/routing/routes.dart';

/// The app's single root [NavigatorState] handle.
///
/// Everything that needs to navigate without a [BuildContext] — the Dio 401
/// interceptor, push-notification taps, session expiry — must go through this
/// key. There used to be a second, independent key on
/// `PushNotificationService`; only that one was wired into `MaterialApp`, so
/// every `NavigationService` call was silently a no-op (`currentState` was
/// always null) and expired sessions never reached the login screen.
class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  /// True once `MaterialApp` has mounted its navigator.
  static bool get isReady => navigatorKey.currentState != null;

  /// Waits for the root navigator to mount, then returns it.
  ///
  /// Cold starts (notification tap on a terminated app) run `main()` before the
  /// first frame, so anything that navigates at startup has to wait. This
  /// replaces the fixed `Future.delayed(800ms)` guess that used to sit in
  /// `PushNotificationService` — too short on a slow cold start (the tap was
  /// dropped), needlessly slow on a warm one.
  /// How long [waitUntilReady] waits for the navigator to appear. Overridable
  /// so tests that exercise no-navigator paths don't sit here for 10 seconds.
  @visibleForTesting
  static Duration readyTimeout = const Duration(seconds: 10);

  static Future<NavigatorState?> waitUntilReady({
    Duration? timeout,
    Duration pollInterval = const Duration(milliseconds: 50),
  }) async {
    final deadline = DateTime.now().add(timeout ?? readyTimeout);
    while (navigatorKey.currentState == null) {
      if (!DateTime.now().isBefore(deadline)) return null;
      await Future<void>.delayed(pollInterval);
    }
    return navigatorKey.currentState;
  }

  /// Guards against two concurrent 401s both racing to the login screen.
  static bool _navigatingToLogin = false;

  /// True while a login redirect is in flight (test/diagnostic hook).
  static bool get isNavigatingToLogin => _navigatingToLogin;

  /// Sends the user to login and drops every route behind it.
  ///
  /// Safe to call from anywhere, any number of times: concurrent callers
  /// collapse into a single navigation, and a call made before the navigator
  /// exists waits for it rather than being dropped.
  static Future<void> goToLoginAndClearStack() async {
    if (_navigatingToLogin) return;
    _navigatingToLogin = true;
    try {
      final nav = await waitUntilReady();
      nav?.pushNamedAndRemoveUntil(Routes.login, (route) => false);
    } finally {
      _navigatingToLogin = false;
    }
  }

  /// Resets the redirect guard. Tests only.
  @visibleForTesting
  static void resetForTest() => _navigatingToLogin = false;
}
