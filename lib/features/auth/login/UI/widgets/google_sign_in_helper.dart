import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Abstraction over the Google sign-in SDK so widgets can depend on an
/// injectable interface instead of a static plugin call — lets tests supply
/// a fake without touching the real `google_sign_in` platform channel.
abstract class GoogleAuthService {
  Future<String?> signInAndGetIdToken();
}

class GoogleSignInAuthService implements GoogleAuthService {
  GoogleSignInAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']);

  final GoogleSignIn _googleSignIn;

  @override
  Future<String?> signInAndGetIdToken() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }
}

/// Kept for backwards compatibility with any other call sites; delegates to
/// [GoogleSignInAuthService].
class GoogleSignInHelper {
  static final GoogleAuthService _service = GoogleSignInAuthService();

  static Future<String?> signInAndGetIdToken() =>
      _service.signInAndGetIdToken();
}
