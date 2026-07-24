import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:riff/firebase_options.dart';

/// Initializes Firebase, tolerating the brief window on iOS where Dart `main()`
/// may run before the native Firebase plugin has registered its method channel.
///
/// On Flutter's UIScene lifecycle (main channel), plugins register when the
/// scene connects — which can land just after `main()` starts. Calling
/// `Firebase.initializeApp` before the `FirebaseCoreHostApi.initializeCore`
/// channel handler exists throws `PlatformException(channel-error)`. Registration
/// completes within a few frames, so we retry briefly instead of crashing.
Future<FirebaseApp> initFirebaseWithRetry({
  int maxAttempts = 40,
  Duration delay = const Duration(milliseconds: 50),
}) async {
  for (var attempt = 1; ; attempt++) {
    try {
      return await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on PlatformException catch (e) {
      // Only the "native side not ready yet" case is retryable. With plugins
      // registered on the app delegate (see ios AppDelegate.swift) this normally
      // succeeds on the first attempt; the retry is a defensive backstop.
      final retryable = e.code == 'channel-error';
      if (!retryable || attempt >= maxAttempts) rethrow;
      await Future<void>.delayed(delay);
    } on FirebaseException catch (e) {
      // App already initialized on a prior attempt — treat as success.
      if (e.code == 'duplicate-app') return Firebase.app();
      rethrow;
    }
  }
}
