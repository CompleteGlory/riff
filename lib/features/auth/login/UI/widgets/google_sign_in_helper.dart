import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInHelper {
  static final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: ['email'],
  );

  static Future<String?> signInAndGetIdToken() async {
    try {
      final account = await googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }
}
