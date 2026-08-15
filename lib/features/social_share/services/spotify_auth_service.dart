import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/services/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Why a [SpotifyAuthService.connect] attempt ended the way it did.
///
/// [connect] used to return a bare `bool`, which meant every failure — a
/// cancelled browser, a client id that never got compiled in, an account
/// Spotify refuses — looked identical to the user: the card simply went back to
/// "Connect Spotify" with no explanation. The status is what lets the UI say
/// something, and [detail] carries Spotify's own error text for the rest.
enum SpotifyConnectStatus {
  /// Connected, and the backend holds the tokens — other users will see
  /// this user's now-playing on their profile.
  connected,

  /// Connected on this device, but the tokens could not be handed to the Riff
  /// backend. Now-playing works on the user's own profile and nowhere else.
  connectedLocalOnly,

  /// The user closed the Spotify browser without approving.
  cancelled,

  /// SPOTIFY_CLIENT_ID was not compiled into this build. Always a build-command
  /// bug, never anything the user did — see CLAUDE.md.
  notConfigured,

  /// Spotify (or the network) rejected the attempt.
  failed,
}

/// The outcome of a connect attempt.
class SpotifyConnectResult {
  const SpotifyConnectResult(this.status, {this.detail});

  final SpotifyConnectStatus status;

  /// Spotify's `error_description` where there was one, for diagnostics.
  final String? detail;

  /// Whether the user ends up connected at all, shared or not.
  bool get isConnected =>
      status == SpotifyConnectStatus.connected ||
      status == SpotifyConnectStatus.connectedLocalOnly;
}

/// Handles Spotify PKCE OAuth 2.0 and token management.
///
/// Flow:
///   1. [connect] — opens Spotify in-app browser, user grants permission.
///   2. Tokens are stored in SharedPreferences *and* on the Riff backend.
///   3. [getAccessToken] — returns a valid token, auto-refreshing if needed.
///   4. [disconnect] — clears local and backend tokens.
///
/// Spotify scopes:
///   • user-read-currently-playing — read currently playing track
///   • user-read-playback-state    — read playback state (paused/playing)
class SpotifyAuthService {
  SpotifyAuthService._();
  static final SpotifyAuthService instance = SpotifyAuthService._();

  // Injected at build time via --dart-define=SPOTIFY_CLIENT_ID=<value>
  // Locally: add to your run/build command or IDE dart-define config.
  // CI: passed by ios/ci_scripts/ci_post_clone.sh and android/fastlane/Fastfile.
  static const _clientId    = String.fromEnvironment('SPOTIFY_CLIENT_ID');
  static const _redirectUri = 'com.riff.app://spotify-callback';
  // Spotify does NOT expose an OpenID Connect discovery document.
  // Must specify auth + token endpoints directly.
  static final _serviceConfig = const AuthorizationServiceConfiguration(
    authorizationEndpoint: 'https://accounts.spotify.com/authorize',
    tokenEndpoint: 'https://accounts.spotify.com/api/token',
  );
  static const _scopes = [
    'user-read-currently-playing',
    'user-read-playback-state',
  ];

  static const _keyAccessToken  = 'spotify_access_token';
  static const _keyRefreshToken = 'spotify_refresh_token';
  static const _keyExpiry       = 'spotify_token_expiry'; // epoch ms as string

  final _appAuth = const FlutterAppAuth();

  /// Whether this build carries a Spotify client id at all.
  static bool get isConfigured => _clientId.isNotEmpty;

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Returns true if the user has connected their Spotify account.
  Future<bool> get isConnected async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyAccessToken);
  }

  /// Initiates the Spotify PKCE OAuth flow.
  Future<SpotifyConnectResult> connect() async {
    // A release build strips asserts, so an absent client id used to sail
    // straight into an authorize call with `client_id=`, which Spotify rejects
    // — and the user saw nothing at all. Check it for real instead.
    if (!isConfigured) {
      debugPrint('[SpotifyAuth] SPOTIFY_CLIENT_ID is empty — pass '
          '--dart-define=SPOTIFY_CLIENT_ID=<id> when building.');
      return const SpotifyConnectResult(SpotifyConnectStatus.notConfigured);
    }

    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUri,
          serviceConfiguration: _serviceConfig,
          scopes: _scopes,
          additionalParameters: {'show_dialog': 'true'},
        ),
      );

      final accessToken = result.accessToken;
      if (accessToken == null) {
        return const SpotifyConnectResult(SpotifyConnectStatus.failed);
      }

      await _saveTokens(
        accessToken,
        result.refreshToken,
        result.accessTokenExpirationDateTime,
      );

      // Persist tokens on the backend so other users can see now-playing.
      // Spotify only returns a refresh token on the initial authorization; if
      // it is somehow absent the connection is still usable locally, so don't
      // throw the whole thing away over it.
      final shared = await _syncTokensToBackend(
        accessToken: accessToken,
        refreshToken: result.refreshToken,
        expiry: result.accessTokenExpirationDateTime,
      );

      return SpotifyConnectResult(shared
          ? SpotifyConnectStatus.connected
          : SpotifyConnectStatus.connectedLocalOnly);
    } on FlutterAppAuthUserCancelledException {
      return const SpotifyConnectResult(SpotifyConnectStatus.cancelled);
    } on FlutterAppAuthPlatformException catch (e) {
      // Spotify's own words. The one worth recognising: an app still in
      // Development Mode on the Spotify dashboard rejects every account that
      // has not been added to its 25-user allowlist, and says so here.
      final details = e.platformErrorDetails;
      debugPrint('[SpotifyAuth] connect failed: $details');
      return SpotifyConnectResult(
        SpotifyConnectStatus.failed,
        detail: details.errorDescription ?? details.error,
      );
    } catch (e) {
      debugPrint('[SpotifyAuth] connect error: $e');
      return const SpotifyConnectResult(SpotifyConnectStatus.failed);
    }
  }

  /// Returns a valid access token, refreshing it silently if expired.
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken  = prefs.getString(_keyAccessToken);
    final refreshToken = prefs.getString(_keyRefreshToken);
    final expiryMs     = int.tryParse(prefs.getString(_keyExpiry) ?? '');

    if (accessToken == null) return null;

    final now      = DateTime.now().millisecondsSinceEpoch;
    final expired  = expiryMs != null && now >= expiryMs - 60000; // 60s buffer

    if (!expired) return accessToken;

    // Attempt silent refresh
    if (refreshToken == null) { await disconnect(); return null; }
    try {
      final result = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUri,
          serviceConfiguration: _serviceConfig,
          refreshToken: refreshToken,
          scopes: _scopes,
        ),
      );
      if (result.accessToken == null) { await disconnect(); return null; }
      await _saveTokens(result.accessToken!, result.refreshToken ?? refreshToken,
          result.accessTokenExpirationDateTime);
      // The backend refreshes its own copy, but a rotated refresh token would
      // strand it on a dead one — keep the two in step.
      await _syncTokensToBackend(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken ?? refreshToken,
        expiry: result.accessTokenExpirationDateTime,
      );
      return result.accessToken;
    } catch (e) {
      debugPrint('[SpotifyAuth] refresh error: $e');
      await disconnect();
      return null;
    }
  }

  /// Clears all stored tokens (user disconnects Spotify).
  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyExpiry);
    // Clear tokens from backend too.
    await _disconnectFromBackend();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<void> _saveTokens(String access, String? refresh, DateTime? expiry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, access);
    if (refresh != null) await prefs.setString(_keyRefreshToken, refresh);
    if (expiry  != null) await prefs.setString(_keyExpiry, expiry.millisecondsSinceEpoch.toString());
  }

  /// POSTs Spotify tokens to the Riff backend so the server can fetch
  /// now-playing on behalf of this user when others view their profile.
  ///
  /// Returns whether the backend actually took them. This used to read the
  /// stored Riff JWT straight out of SharedPreferences and post it with bare
  /// `http`, which bypasses the Dio interceptor that refreshes on 401 — and
  /// Riff access tokens live 15 minutes. Connect Spotify a quarter of an hour
  /// after opening the app and the sync 401'd into a `catch` that only
  /// `debugPrint`ed: the user looked connected, their own card worked, and
  /// nobody else ever saw their now-playing. Ask [SessionManager] for a token
  /// that is valid *now* instead.
  Future<bool> _syncTokensToBackend({
    required String accessToken,
    required String? refreshToken,
    required DateTime? expiry,
  }) async {
    try {
      final jwt = await SessionManager.instance.validAccessToken();
      if (jwt == null || jwt.isEmpty) return false;

      final expiresIn = expiry != null
          ? expiry.difference(DateTime.now()).inSeconds.clamp(0, 3600)
          : 3600;

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBASEURL}${ApiConstants.spotifyConnect}'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'expiresIn': expiresIn,
        }),
      );

      final ok = response.statusCode >= 200 && response.statusCode < 300;
      if (!ok) {
        debugPrint('[SpotifyAuth] backend sync rejected: '
            '${response.statusCode} ${response.body}');
      }
      return ok;
    } catch (e) {
      debugPrint('[SpotifyAuth] backend sync error: $e');
      return false;
    }
  }

  /// Tells the backend to clear this user's stored Spotify tokens.
  Future<void> _disconnectFromBackend() async {
    try {
      final jwt = await SessionManager.instance.validAccessToken();
      if (jwt == null || jwt.isEmpty) return;

      await http.delete(
        Uri.parse('${ApiConstants.apiBASEURL}${ApiConstants.spotifyDisconnect}'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
    } catch (e) {
      debugPrint('[SpotifyAuth] backend disconnect error: $e');
    }
  }
}
