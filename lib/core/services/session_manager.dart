import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/connectivity_service.dart';
import 'package:riff/core/routing/navigation_service.dart';

/// Outcome of one call to `POST /api/auth/refresh`.
class RefreshOutcome {
  const RefreshOutcome._({
    this.accessToken,
    this.refreshToken,
    required this.authRejected,
  });

  /// The server issued a new token pair.
  const RefreshOutcome.success({
    required String accessToken,
    String? refreshToken,
  }) : this._(
          accessToken: accessToken,
          refreshToken: refreshToken,
          authRejected: false,
        );

  /// The server rejected the refresh token (401/403). The session is over.
  const RefreshOutcome.rejected() : this._(authRejected: true);

  /// Network error, timeout, 5xx — the session may still be valid, so the user
  /// must NOT be signed out over it.
  const RefreshOutcome.transientFailure() : this._(authRejected: false);

  final String? accessToken;
  final String? refreshToken;
  final bool authRejected;

  bool get succeeded => accessToken != null && accessToken!.isNotEmpty;
}

/// Calls the refresh endpoint. Swappable so tests never touch the network.
typedef RefreshTransport = Future<RefreshOutcome> Function(String refreshToken);

/// Owns the access/refresh token lifecycle for the whole app.
///
/// Two things here fix long-standing "I got randomly signed out" reports:
///
/// 1. **Single-flight refresh.** The API rotates refresh tokens and only stores
///    a hash of the newest one (`LogIn.execute` is what `/auth/refresh` runs).
///    The old interceptor refreshed once per failed request, so a burst of
///    401s — posting a comment while the feed, the chat list and the 30-second
///    notification poll were all in flight — fired several refreshes with the
///    same token. The first rotated it; every other one came back 401 and was
///    treated as "session over". Worse, the loser could overwrite storage with
///    an already-invalidated refresh token, poisoning the session permanently.
///    All callers now share one in-flight refresh.
///
/// 2. **Only a real rejection ends the session.** A network blip during refresh,
///    or a retried request that fails for an unrelated reason, no longer signs
///    the user out.
///
/// 3. **A refresh gets several chances before the session is declared over.**
///    A transient failure is retried on a backoff instead of leaving the caller
///    with a dead token; a rejection has to be *confirmed* by a second attempt;
///    a rejection that arrives while the device is offline is not believed at
///    all; and a rejection for a refresh token that storage has since rotated
///    is retried with the newer token rather than ending the session over a
///    race. Between them these cover the "signed out for no reason on a bad
///    connection" reports.
class SessionManager {
  SessionManager._();

  static SessionManager instance = SessionManager._();

  /// Replaces the singleton. Tests only.
  @visibleForTesting
  static void setInstanceForTest(SessionManager manager) => instance = manager;

  /// Restores the real singleton. Tests only.
  @visibleForTesting
  static void resetInstanceForTest() => instance = SessionManager._();

  /// Refresh a token slightly before it actually expires, so a request (or a
  /// socket handshake) never leaves with a token that dies in flight.
  static const Duration expiryLeeway = Duration(seconds: 30);

  /// How many times one refresh will talk to the server before giving up.
  static const int maxRefreshAttempts = 4;

  /// How many *confirmed* rejections it takes to end the session. A single 401
  /// on `/auth/refresh` is not proof: the endpoint rotates the token, so a
  /// rejection can just as easily mean "you lost a race" as "your session is
  /// over", and losing the race used to sign people out mid-scroll.
  static const int requiredRejections = 2;

  /// Delay before each retry, by attempt index.
  static const List<Duration> retryBackoff = [
    Duration(seconds: 1),
    Duration(seconds: 3),
    Duration(seconds: 6),
  ];

  /// Overridable delay so tests don't sit through the backoff.
  @visibleForTesting
  Future<void> Function(Duration)? sleep;

  final _tokenRefreshedController = StreamController<String>.broadcast();

  /// Emits the new access token every time it is refreshed.
  ///
  /// Socket connections authenticate with the access token at handshake time
  /// and are never re-authenticated afterwards, so they have to listen here and
  /// reconnect — otherwise they stay dead for the rest of the process while
  /// HTTP keeps working, which is exactly the "I can't send messages until I
  /// restart the app" bug.
  Stream<String> get onAccessTokenRefreshed => _tokenRefreshedController.stream;

  /// Runs on session end (clear per-user cubit state, drop sockets, …).
  /// Registered from `setUpGetIt()` so this class stays free of DI imports.
  final List<FutureOr<void> Function()> sessionEndHooks = [];

  Future<String?>? _inFlightRefresh;

  /// Overridable transport — defaults to the real endpoint.
  RefreshTransport? refreshTransport;

  // ── Token access ──────────────────────────────────────────────────────────

  /// The stored access token, or `''` when signed out.
  Future<String> currentAccessToken() async =>
      await SharedPrefHelper.getString(SharedPrefKeys.userToken) as String? ??
      '';

  /// The stored refresh token, or `''` when signed out.
  Future<String> currentRefreshToken() async =>
      await SharedPrefHelper.getString(SharedPrefKeys.refreshToken)
          as String? ??
      '';

  /// An access token guaranteed to be usable right now, refreshing first if the
  /// stored one is expired. Returns `null` when there is no usable session.
  ///
  /// Access tokens live 15 minutes, so anything that resumes after a while —
  /// most of all opening the app from a push notification — is likely holding
  /// an expired one. HTTP survived that because the 401 interceptor refreshed
  /// on demand; socket handshakes did not, and were rejected outright.
  Future<String?> validAccessToken() async {
    final token = await currentAccessToken();
    if (token.isNotEmpty && !isExpired(token)) return token;
    if (token.isEmpty && (await currentRefreshToken()).isEmpty) return null;
    return refreshAccessToken();
  }

  /// Whether [jwt] is expired (or expires within [leeway]).
  ///
  /// A token that cannot be parsed is treated as **not** expired — better to
  /// let the server be the judge via a 401 than to force a refresh loop over an
  /// unfamiliar token shape.
  bool isExpired(String jwt, {Duration leeway = expiryLeeway}) {
    final expiry = expiryOf(jwt);
    if (expiry == null) return false;
    return DateTime.now().toUtc().add(leeway).isAfter(expiry);
  }

  /// The `exp` claim of [jwt] as UTC, or null if it can't be read.
  DateTime? expiryOf(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return null;
      final exp = payload['exp'];
      if (exp is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    } catch (_) {
      return null;
    }
  }

  // ── Refresh ───────────────────────────────────────────────────────────────

  /// Refreshes the access token, collapsing concurrent callers into one
  /// network round-trip. Returns the new access token, or `null` on failure.
  ///
  /// Ends the session only when the server actually rejects the refresh token.
  Future<String?> refreshAccessToken() {
    return _inFlightRefresh ??= _performRefresh().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  Future<String?> _performRefresh() async {
    var refreshToken = await currentRefreshToken();
    if (refreshToken.isEmpty) {
      debugPrint('SessionManager: no refresh token — ending session');
      await endSession();
      return null;
    }

    final transport = refreshTransport ?? _defaultRefreshTransport;
    var rejections = 0;

    for (var attempt = 0; attempt < maxRefreshAttempts; attempt++) {
      final outcome = await transport(refreshToken);

      if (outcome.succeeded) return _storeRefreshedTokens(outcome);

      if (outcome.authRejected) {
        // A rejection while the device has no connectivity is far more likely
        // to be a captive portal or a proxy inventing a response than the
        // server actually revoking the session.
        if (ConnectivityService.instance.isOffline) {
          debugPrint('SessionManager: refresh rejected while offline — '
              'session kept');
          return null;
        }

        // Another flow may have rotated the token while this call was in
        // flight. Retrying with the newer one is not a second chance at a bad
        // token — it is the first chance at the right one.
        final stored = await currentRefreshToken();
        if (stored.isNotEmpty && stored != refreshToken) {
          debugPrint('SessionManager: refresh token rotated mid-flight — '
              'retrying with the stored one');
          refreshToken = stored;
          continue;
        }

        rejections++;
        if (rejections < requiredRejections &&
            attempt + 1 < maxRefreshAttempts) {
          debugPrint('SessionManager: refresh rejected — confirming before '
              'ending the session');
          await _wait(_backoffFor(attempt));
          continue;
        }

        debugPrint('SessionManager: refresh rejected twice — ending session');
        await endSession();
        return null;
      }

      // Transient (offline, timeout, 5xx). Keep the session and try again on a
      // backoff; the old code gave up after one attempt, which on a flaky
      // connection meant every request in the burst failed for no good reason.
      if (attempt + 1 < maxRefreshAttempts) {
        debugPrint('SessionManager: refresh failed transiently — retrying');
        await _wait(_backoffFor(attempt));
        continue;
      }

      debugPrint('SessionManager: refresh failed transiently — session kept');
      return null;
    }

    return null;
  }

  Future<String?> _storeRefreshedTokens(RefreshOutcome outcome) async {
    final newAccess = outcome.accessToken!;
    await SharedPrefHelper.setData(SharedPrefKeys.userToken, newAccess);
    if (outcome.refreshToken != null && outcome.refreshToken!.isNotEmpty) {
      await SharedPrefHelper.setData(
        SharedPrefKeys.refreshToken,
        outcome.refreshToken!,
      );
    }
    if (!_tokenRefreshedController.isClosed) {
      _tokenRefreshedController.add(newAccess);
    }
    return newAccess;
  }

  Duration _backoffFor(int attempt) =>
      retryBackoff[attempt.clamp(0, retryBackoff.length - 1)];

  Future<void> _wait(Duration d) => (sleep ?? Future<void>.delayed)(d);

  Future<RefreshOutcome> _defaultRefreshTransport(String refreshToken) async {
    try {
      // A bare Dio: no interceptors, so a failing refresh can't recurse into
      // another refresh.
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.apiBASEURL,
        headers: {'Cookie': 'RefreshToken=$refreshToken'},
        validateStatus: (status) => status != null && status < 500,
      ));

      final response = await dio.post<void>(ApiConstants.refreshToken);
      // This Dio deliberately has no interceptors, so the connectivity signal
      // the app's main Dio publishes has to be reported by hand here.
      ConnectivityService.instance.reportReachable();
      final status = response.statusCode ?? 0;

      if (status == 401 || status == 403) return const RefreshOutcome.rejected();
      if (status < 200 || status >= 300) {
        return const RefreshOutcome.transientFailure();
      }

      final cookies = response.headers.map['set-cookie'] ?? const <String>[];
      String? access;
      String? refresh;
      for (final cookie in cookies) {
        if (cookie.startsWith('AccessToken=')) {
          access = cookie.split(';').first.replaceFirst('AccessToken=', '');
        } else if (cookie.startsWith('RefreshToken=')) {
          refresh = cookie.split(';').first.replaceFirst('RefreshToken=', '');
        }
      }

      if (access == null || access.isEmpty) {
        // 200 with no token is a server contract break, not proof the refresh
        // token is bad — don't sign the user out over it.
        return const RefreshOutcome.transientFailure();
      }
      return RefreshOutcome.success(accessToken: access, refreshToken: refresh);
    } on DioException catch (e) {
      ConnectivityService.instance.reportDioError(e);
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) return const RefreshOutcome.rejected();
      return const RefreshOutcome.transientFailure();
    } catch (_) {
      return const RefreshOutcome.transientFailure();
    }
  }

  // ── Session teardown ──────────────────────────────────────────────────────

  bool _endingSession = false;

  /// Clears credentials, runs every teardown hook, and routes to login.
  ///
  /// The theme/locale preferences are deliberately left alone.
  Future<void> endSession({bool navigateToLogin = true}) async {
    if (_endingSession) return;
    _endingSession = true;
    try {
      await SharedPrefHelper.removeData(SharedPrefKeys.userToken);
      await SharedPrefHelper.removeData(SharedPrefKeys.refreshToken);
      await SharedPrefHelper.removeData(SharedPrefKeys.userId);
      await SharedPrefHelper.removeData(SharedPrefKeys.userProfileImage);
      await SharedPrefHelper.removeData(SharedPrefKeys.firstName);
      await SharedPrefHelper.removeData(SharedPrefKeys.lastName);

      for (final hook in sessionEndHooks) {
        try {
          await hook();
        } catch (_) {
          // One misbehaving hook must not block the rest of the teardown.
        }
      }

      if (navigateToLogin) {
        await NavigationService.goToLoginAndClearStack();
      }
    } finally {
      _endingSession = false;
    }
  }

  /// True when both tokens are present in storage.
  Future<bool> hasStoredSession() async {
    final access = await currentAccessToken();
    final refresh = await currentRefreshToken();
    return access.isNotEmpty && refresh.isNotEmpty;
  }

  @visibleForTesting
  Future<void> dispose() => _tokenRefreshedController.close();
}
