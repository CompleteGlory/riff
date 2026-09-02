import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Why a Sign in with Apple attempt ended the way it did.
enum AppleSignInStatus { success, cancelled, unavailable, failed }

/// The outcome of an attempt.
class AppleSignInResult {
  const AppleSignInResult(this.status, {this.credential, this.detail});

  final AppleSignInStatus status;
  final AppleCredential? credential;

  /// Apple's own error text, when there was one.
  final String? detail;

  bool get isSuccess => status == AppleSignInStatus.success;
}

/// What a completed Sign in with Apple attempt yields.
class AppleCredential {
  const AppleCredential({required this.identityToken, this.fullName});

  final String identityToken;

  /// Apple returns the name on the **first** authorization only, and never in
  /// the identity token. Null on every later sign-in, which is normal.
  final String? fullName;
}

/// Abstraction over the Sign in with Apple SDK, mirroring [GoogleAuthService]
/// so widgets depend on an injectable interface rather than a static plugin
/// call — which is what lets the login widget tests run without the platform
/// channel.
abstract class AppleAuthService {
  /// Whether this device can offer Sign in with Apple at all.
  Future<bool> isAvailable();

  Future<AppleSignInResult> signIn();
}

class SignInWithAppleService implements AppleAuthService {
  @override
  Future<bool> isAvailable() async {
    // Android and web can use Apple's web flow, but that needs a Services ID
    // and a return URL configured on Apple's side, none of which exists here.
    // Guideline 4.8 is an iOS requirement, so keep it to iOS.
    if (kIsWeb) return false;
    try {
      if (!Platform.isIOS) return false;
    } catch (_) {
      return false;
    }
    return SignInWithApple.isAvailable();
  }

  @override
  Future<AppleSignInResult> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final token = credential.identityToken;
      if (token == null || token.isEmpty) {
        debugPrint('Apple Sign-In: no identity token returned');
        return const AppleSignInResult(AppleSignInStatus.failed);
      }

      // givenName/familyName are populated only on the first authorization.
      final parts = [credential.givenName, credential.familyName]
          .whereType<String>()
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      return AppleSignInResult(
        AppleSignInStatus.success,
        credential: AppleCredential(
          identityToken: token,
          fullName: parts.isEmpty ? null : parts.join(' '),
        ),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // Cancelling is a normal outcome, not an error worth surfacing.
      if (e.code == AuthorizationErrorCode.canceled) {
        return const AppleSignInResult(AppleSignInStatus.cancelled);
      }
      debugPrint('Apple Sign-In error: ${e.code} ${e.message}');
      return AppleSignInResult(
        AppleSignInStatus.failed,
        detail: e.message.isEmpty ? '${e.code}' : e.message,
      );
    } catch (e) {
      debugPrint('Apple Sign-In error: $e');
      return AppleSignInResult(AppleSignInStatus.failed, detail: '$e');
    }
  }
}
