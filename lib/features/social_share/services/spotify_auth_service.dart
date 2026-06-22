import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles Spotify PKCE OAuth 2.0 and token management.
///
/// Flow:
///   1. [connect] — opens Spotify in-app browser, user grants permission.
///   2. Tokens are stored in SharedPreferences.
///   3. [getAccessToken] — returns a valid token, auto-refreshing if needed.
///   4. [disconnect] — clears local tokens.
///
/// Spotify scopes:
///   • user-read-currently-playing — read currently playing track
///   • user-read-playback-state    — read playback state (paused/playing)
class SpotifyAuthService {
  SpotifyAuthService._();
  static final SpotifyAuthService instance = SpotifyAuthService._();

  // Injected at build time via --dart-define=SPOTIFY_CLIENT_ID=<value>
  // Locally: add to your run/build command or IDE dart-define config.
  // CI: stored as GitHub secret SPOTIFY_CLIENT_ID, passed via Fastfile.
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

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Returns true if the user has connected their Spotify account.
  Future<bool> get isConnected async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyAccessToken);
  }

  /// Initiates the Spotify PKCE OAuth flow.
  /// Returns true on success, false if the user cancelled or an error occurred.
  Future<bool> connect() async {
    assert(_clientId.isNotEmpty,
        'SPOTIFY_CLIENT_ID is empty — pass --dart-define=SPOTIFY_CLIENT_ID=<id> to flutter run');
    debugPrint('[SpotifyAuth] using clientId: "$_clientId"');
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
      await _saveTokens(result.accessToken, result.refreshToken, result.accessTokenExpirationDateTime);
      // Persist tokens on the backend so other users can see now-playing.
      await _syncTokensToBackend(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken!,
        expiry: result.accessTokenExpirationDateTime,
      );
      return true;
    } catch (e) {
      debugPrint('[SpotifyAuth] connect error: $e');
      return false;
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
      await _saveTokens(result.accessToken, result.refreshToken ?? refreshToken, result.accessTokenExpirationDateTime);
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

  Future<void> _saveTokens(String? access, String? refresh, DateTime? expiry) async {
    if (access == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, access);
    if (refresh != null) await prefs.setString(_keyRefreshToken, refresh);
    if (expiry  != null) await prefs.setString(_keyExpiry, expiry.millisecondsSinceEpoch.toString());
  }

  /// POSTs Spotify tokens to the Riff backend so the server can fetch
  /// now-playing on behalf of this user when others view their profile.
  Future<void> _syncTokensToBackend({
    required String accessToken,
    required String refreshToken,
    required DateTime? expiry,
  }) async {
    try {
      final jwt = await SharedPrefHelper.getString(SharedPrefKeys.userToken) as String? ?? '';
      if (jwt.isEmpty) return;

      final expiresIn = expiry != null
          ? expiry.difference(DateTime.now()).inSeconds.clamp(0, 3600)
          : 3600;

      await http.post(
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
    } catch (e) {
      debugPrint('[SpotifyAuth] backend sync error: $e');
    }
  }

  /// Tells the backend to clear this user's stored Spotify tokens.
  Future<void> _disconnectFromBackend() async {
    try {
      final jwt = await SharedPrefHelper.getString(SharedPrefKeys.userToken) as String? ?? '';
      if (jwt.isEmpty) return;

      await http.delete(
        Uri.parse('${ApiConstants.apiBASEURL}${ApiConstants.spotifyDisconnect}'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
    } catch (e) {
      debugPrint('[SpotifyAuth] backend disconnect error: $e');
    }
  }
}
