import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/services/push_notification_service.dart';
import 'package:riff/firebase_options.dart';
import 'package:riff/riff_app.dart';
import 'core/routing/app_router.dart';
import 'core/di/dependency_injection.dart';
import 'core/helpers/shared_pref_helper.dart';

/// Top-level handler for background / terminated FCM messages.
/// Must be a top-level function (not a method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background messages are shown as system notifications by the OS automatically.
  // Nothing extra needed here unless you want to update local state.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  setUpGetIt();

  final isLoggedIn = await checkIfLoggedIn();
  if (isLoggedIn) {
    // Init push after confirming user is logged in so token send has a valid JWT
    PushNotificationService.instance.init();
  }

  final privacyAccepted = await SharedPrefHelper.getBool(
      SharedPrefKeys.privacyPolicyAccepted) as bool;

  runApp(RiffApp(
    appRouter: AppRouter(),
    startAtHome: isLoggedIn,
    needsPrivacyAccept: !privacyAccepted,
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
