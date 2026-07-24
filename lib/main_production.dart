import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/services/firebase_init.dart';
import 'package:riff/core/services/push_notification_service.dart';
import 'package:riff/riff_app.dart';
import 'core/routing/app_router.dart';
import 'core/di/dependency_injection.dart';
import 'core/helpers/shared_pref_helper.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await initFirebaseWithRetry();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebaseWithRetry();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  setUpGetIt();

  final isLoggedIn = await checkIfLoggedIn();
  if (isLoggedIn) {
    PushNotificationService.instance.init();
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
