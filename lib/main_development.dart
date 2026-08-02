import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/services/firebase_init.dart';
import 'package:riff/core/services/push_notification_service.dart';
import 'package:riff/riff_app.dart';
import 'core/routing/app_router.dart';
import 'core/di/dependency_injection.dart';
import 'core/helpers/shared_pref_helper.dart';

/// Top-level handler for background / terminated FCM messages.
/// Must be a top-level function (not a method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await initFirebaseWithRetry();
  // Background messages are shown as system notifications by the OS automatically.
  // Nothing extra needed here unless you want to update local state.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebaseWithRetry();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Must be awaited: setUpGetIt() itself awaits DioFactory.getDio(), and
  // HomeLayout resolves singletons out of getIt in initState(). Firing it
  // without awaiting left a race where a fast first frame reached getIt before
  // registration finished.
  await setUpGetIt();

  final isLoggedIn = await checkIfLoggedIn();
  if (isLoggedIn) {
    // Init push after confirming user is logged in so token send has a valid JWT
    unawaited(PushNotificationService.instance.init());
  }

  runApp(RiffApp(
    appRouter: AppRouter(),
    startAtHome: isLoggedIn,
  ));
}

/// Returns true if both access token and refresh token exist
Future<bool> checkIfLoggedIn() async {
  final userToken = await SharedPrefHelper.getString(SharedPrefKeys.userToken);
  final refreshToken = await SharedPrefHelper.getString(SharedPrefKeys.refreshToken);

  return userToken != null &&
      userToken.isNotEmpty &&
      refreshToken != null &&
      refreshToken.isNotEmpty;
}
