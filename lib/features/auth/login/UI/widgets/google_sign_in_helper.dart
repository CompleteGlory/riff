import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Why a Google sign-in attempt ended the way it did.
///
/// The service used to return a bare `String?`, which collapsed three very
/// different outcomes into one null: the user cancelled, the plugin threw, and
/// the plugin succeeded but handed back no ID token. All three showed the same
/// "cancelled or failed" message, so a total production outage was
/// indistinguishable from someone tapping Cancel.
enum GoogleSignInStatus {
  /// Signed in and an ID token came back.
  success,

  /// The user dismissed the account picker. Not an error.
  cancelled,

  /// Signed in, but the plugin returned no ID token.
  ///
  /// Almost always configuration rather than anything the user did: on Android
  /// an ID token is only issued when a server client id is available (the
  /// `default_web_client_id` resource generated from google-services.json), and
  /// on iOS when the client id is present in GoogleService-Info.plist.
  noIdToken,

  /// The plugin threw — network, a revoked OAuth client, or a platform-side
  /// rejection such as the legacy Google Sign-In API being withdrawn.
  failed,
}

class GoogleSignInResult {
  const GoogleSignInResult(this.status, {this.idToken, this.detail});

  final GoogleSignInStatus status;
  final String? idToken;

  /// The underlying error text, when there was one, for diagnostics.
  final String? detail;

  bool get isSuccess => status == GoogleSignInStatus.success;
}

/// Abstraction over the Google sign-in SDK so widgets can depend on an
/// injectable interface instead of a static plugin call — lets tests supply
/// a fake without touching the real `google_sign_in` platform channel.
abstract class GoogleAuthService {
  Future<GoogleSignInResult> signIn();
}

class GoogleSignInAuthService implements GoogleAuthService {
  /// The web/server OAuth client id.
  ///
  /// Passed explicitly rather than left to the platform to discover. Android
  /// only issues an ID token when a server client id is available, and until
  /// now that came from the `default_web_client_id` string resource the
  /// google-services Gradle plugin generates out of google-services.json — so
  /// sign-in silently produced no token if that file lost its web client, a
  /// new flavour shipped without one, or the plugin stopped running. None of
  /// those announce themselves; they just look like every user failing to log
  /// in.
  ///
  /// A `defaultValue` is deliberate. `String.fromEnvironment` with no default
  /// resolves to the empty string when the define is absent, and release
  /// builds strip the assert that would have caught it — which is exactly how
  /// Connect Spotify shipped broken in 1.0.14. Overriding via
  /// --dart-define=GOOGLE_SERVER_CLIENT_ID is possible but never required.
  ///
  /// This is a public OAuth client identifier: it already ships inside
  /// google-services.json and the app binary, so there is nothing to leak.
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '369305642937-rh8uuhr2cife2hj4rkgqcms1j29mfru9.apps.googleusercontent.com',
  );

  GoogleSignInAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email'],
              serverClientId: _serverClientId,
            );

  final GoogleSignIn _googleSignIn;

  @override
  Future<GoogleSignInResult> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return const GoogleSignInResult(GoogleSignInStatus.cancelled);
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        debugPrint('Google Sign-In: signed in as ${account.email} but no ID '
            'token was returned — check the server client id configuration.');
        return const GoogleSignInResult(GoogleSignInStatus.noIdToken);
      }

      return GoogleSignInResult(GoogleSignInStatus.success, idToken: idToken);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return GoogleSignInResult(GoogleSignInStatus.failed, detail: '$e');
    }
  }
}
