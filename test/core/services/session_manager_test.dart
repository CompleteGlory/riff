import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/networks/connectivity_service.dart';
import 'package:riff/core/routing/navigation_service.dart';
import 'package:riff/core/services/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// See session_manager_test.md for what this covers and why.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionManager session;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SessionManager.resetInstanceForTest();
    ConnectivityService.resetInstanceForTest();
    session = SessionManager.instance;
    // A refresh now retries on a backoff before giving up. Skip the waiting so
    // the suite doesn't sit through ten real seconds per failure case.
    session.sleep = (_) async {};
    // No MaterialApp here, so the login redirect has no navigator to find.
    // Without this it would poll for the full production timeout.
    NavigationService.readyTimeout = const Duration(milliseconds: 20);
    NavigationService.resetForTest();
  });

  tearDown(() {
    NavigationService.readyTimeout = const Duration(seconds: 10);
    ConnectivityService.resetInstanceForTest();
  });

  /// Builds an unsigned JWT whose payload carries [exp].
  String jwtExpiringAt(DateTime expiry) {
    String segment(Map<String, dynamic> map) =>
        base64Url.encode(utf8.encode(json.encode(map))).replaceAll('=', '');
    final header = segment({'alg': 'HS256', 'typ': 'JWT'});
    final payload = segment({
      'sub': 'user-1',
      'exp': expiry.millisecondsSinceEpoch ~/ 1000,
    });
    return '$header.$payload.signature';
  }

  Future<void> storeTokens({String? access, String? refresh}) async {
    final prefs = await SharedPreferences.getInstance();
    if (access != null) await prefs.setString(SharedPrefKeys.userToken, access);
    if (refresh != null) {
      await prefs.setString(SharedPrefKeys.refreshToken, refresh);
    }
  }

  group('token expiry', () {
    test('reads the exp claim out of a JWT', () {
      final expiry = DateTime.now().toUtc().add(const Duration(hours: 1));
      final decoded = session.expiryOf(jwtExpiringAt(expiry));

      expect(decoded, isNotNull);
      expect(
        decoded!.difference(expiry).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
    });

    test('a token in the past is expired', () {
      final token =
          jwtExpiringAt(DateTime.now().toUtc().subtract(const Duration(minutes: 1)));

      expect(session.isExpired(token), isTrue);
    });

    test('a token expiring inside the leeway counts as expired', () {
      // Access tokens live 15 minutes; one about to die mid-flight is no good
      // for a socket handshake that is never re-authenticated afterwards.
      final token =
          jwtExpiringAt(DateTime.now().toUtc().add(const Duration(seconds: 5)));

      expect(session.isExpired(token), isTrue);
    });

    test('a comfortably valid token is not expired', () {
      final token =
          jwtExpiringAt(DateTime.now().toUtc().add(const Duration(minutes: 10)));

      expect(session.isExpired(token), isFalse);
    });

    test('an unparseable token is left for the server to reject', () {
      // Better a single 401 than a refresh loop over a token shape we don't
      // recognise.
      expect(session.isExpired('not-a-jwt'), isFalse);
      expect(session.expiryOf('not-a-jwt'), isNull);
    });
  });

  group('refreshAccessToken', () {
    test('stores the rotated token pair and returns the new access token',
        () async {
      await storeTokens(access: 'old-access', refresh: 'old-refresh');
      session.refreshTransport = (_) async => const RefreshOutcome.success(
            accessToken: 'new-access',
            refreshToken: 'new-refresh',
          );

      final token = await session.refreshAccessToken();

      expect(token, 'new-access');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPrefKeys.userToken), 'new-access');
      expect(prefs.getString(SharedPrefKeys.refreshToken), 'new-refresh');
    });

    test('announces the new token so live sockets can reconnect', () async {
      await storeTokens(access: 'old-access', refresh: 'old-refresh');
      session.refreshTransport = (_) async =>
          const RefreshOutcome.success(accessToken: 'new-access');

      final announced = expectLater(
        session.onAccessTokenRefreshed,
        emits('new-access'),
      );
      await session.refreshAccessToken();
      await announced;
    });

    // The regression this whole class exists for. /auth/refresh rotates the
    // refresh token and only keeps a hash of the newest one, so firing one
    // refresh per failed request meant the first call invalidated the token the
    // others were still holding — every loser came back 401 and got treated as
    // "your session is over". Posting a comment while the feed, chat list and
    // 30-second notification poll were in flight was enough to trigger it.
    test('concurrent callers share a single refresh round-trip', () async {
      await storeTokens(access: 'old-access', refresh: 'old-refresh');
      var calls = 0;
      session.refreshTransport = (_) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return const RefreshOutcome.success(accessToken: 'new-access');
      };

      final results = await Future.wait([
        session.refreshAccessToken(),
        session.refreshAccessToken(),
        session.refreshAccessToken(),
        session.refreshAccessToken(),
      ]);

      expect(calls, 1);
      expect(results, everyElement('new-access'));
    });

    test('a later refresh starts a fresh round-trip', () async {
      await storeTokens(access: 'old-access', refresh: 'old-refresh');
      var calls = 0;
      session.refreshTransport = (_) async {
        calls++;
        return RefreshOutcome.success(accessToken: 'access-$calls');
      };

      expect(await session.refreshAccessToken(), 'access-1');
      expect(await session.refreshAccessToken(), 'access-2');
      expect(calls, 2);
    });

    test('always sends the refresh token currently in storage', () async {
      await storeTokens(access: 'old-access', refresh: 'stored-refresh');
      String? sent;
      session.refreshTransport = (token) async {
        sent = token;
        return const RefreshOutcome.success(accessToken: 'new-access');
      };

      await session.refreshAccessToken();

      expect(sent, 'stored-refresh');
    });

    test('a rejected refresh ends the session and wipes credentials', () async {
      await storeTokens(access: 'old-access', refresh: 'old-refresh');
      session.refreshTransport = (_) async => const RefreshOutcome.rejected();

      final token = await session.refreshAccessToken();

      expect(token, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPrefKeys.userToken), isNull);
      expect(prefs.getString(SharedPrefKeys.refreshToken), isNull);
    });

    // A dropped connection must not look like a revoked session — this is the
    // other half of the "randomly signed out" complaint.
    test('a transient failure keeps the session intact', () async {
      await storeTokens(access: 'old-access', refresh: 'old-refresh');
      session.refreshTransport =
          (_) async => const RefreshOutcome.transientFailure();

      final token = await session.refreshAccessToken();

      expect(token, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPrefKeys.userToken), 'old-access');
      expect(prefs.getString(SharedPrefKeys.refreshToken), 'old-refresh');
    });

    test('no stored refresh token ends the session without a network call',
        () async {
      var called = false;
      session.refreshTransport = (_) async {
        called = true;
        return const RefreshOutcome.transientFailure();
      };

      expect(await session.refreshAccessToken(), isNull);
      expect(called, isFalse);
    });
  });

  // Everything here exists because of one report: "I get signed out for no
  // reason." A single 401 on /auth/refresh is not proof the session is over —
  // the endpoint rotates the token, so it can equally mean this caller lost a
  // race — and none of it is trustworthy at all when the device is offline.
  group('refresh resilience', () {
    test('a transient failure is retried before the caller gives up', () async {
      await storeTokens(access: 'old-access', refresh: 'old-refresh');
      var attempts = 0;
      session.refreshTransport = (_) async {
        attempts++;
        if (attempts < 3) return const RefreshOutcome.transientFailure();
        return const RefreshOutcome.success(accessToken: 'fresh-access');
      };

      expect(await session.refreshAccessToken(), 'fresh-access');
      expect(attempts, 3);
    });

    test('one rejection is not enough to end the session', () async {
      await storeTokens(access: 'old-access', refresh: 'old-refresh');
      var attempts = 0;
      session.refreshTransport = (_) async {
        attempts++;
        if (attempts == 1) return const RefreshOutcome.rejected();
        return const RefreshOutcome.success(accessToken: 'fresh-access');
      };

      expect(await session.refreshAccessToken(), 'fresh-access');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPrefKeys.userToken), 'fresh-access');
    });

    test('a rejection while offline never ends the session', () async {
      await storeTokens(access: 'old-access', refresh: 'old-refresh');
      // Force the offline verdict the way the network layer would.
      ConnectivityService.instance.probe = () async => false;
      await ConnectivityService.instance.checkNow();
      expect(ConnectivityService.instance.isOffline, isTrue);

      var attempts = 0;
      session.refreshTransport = (_) async {
        attempts++;
        return const RefreshOutcome.rejected();
      };

      expect(await session.refreshAccessToken(), isNull);
      // Believed once, acted on never.
      expect(attempts, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPrefKeys.userToken), 'old-access');
      expect(prefs.getString(SharedPrefKeys.refreshToken), 'old-refresh');
    });

    // The exact shape of the original bug: a concurrent refresh rotated the
    // token, this one came back 401 holding the stale one, and the user was
    // signed out mid-scroll.
    test('a rejection for a token storage has since rotated is retried with '
        'the new one', () async {
      await storeTokens(access: 'old-access', refresh: 'old-refresh');
      final sent = <String>[];
      session.refreshTransport = (token) async {
        sent.add(token);
        if (token == 'old-refresh') {
          // Simulate the winner of the race writing its rotated token.
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(SharedPrefKeys.refreshToken, 'rotated-refresh');
          return const RefreshOutcome.rejected();
        }
        return const RefreshOutcome.success(accessToken: 'fresh-access');
      };

      expect(await session.refreshAccessToken(), 'fresh-access');
      expect(sent, ['old-refresh', 'rotated-refresh']);
    });

    test('two confirmed rejections do end the session', () async {
      await storeTokens(access: 'old-access', refresh: 'old-refresh');
      var attempts = 0;
      session.refreshTransport = (_) async {
        attempts++;
        return const RefreshOutcome.rejected();
      };

      expect(await session.refreshAccessToken(), isNull);
      expect(attempts, SessionManager.requiredRejections);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPrefKeys.refreshToken), isNull);
    });
  });

  group('validAccessToken', () {
    test('returns the stored token untouched while it is still valid',
        () async {
      final valid =
          jwtExpiringAt(DateTime.now().toUtc().add(const Duration(minutes: 10)));
      await storeTokens(access: valid, refresh: 'refresh');
      var refreshed = false;
      session.refreshTransport = (_) async {
        refreshed = true;
        return const RefreshOutcome.success(accessToken: 'new-access');
      };

      expect(await session.validAccessToken(), valid);
      expect(refreshed, isFalse);
    });

    // The "I can't send messages until I restart the app" bug: the chat gateway
    // verifies the access token during the handshake and hangs up when it
    // fails, so connecting with the expired token straight out of storage left
    // a socket that never delivered anything.
    test('refreshes first when the stored token has expired', () async {
      final expired =
          jwtExpiringAt(DateTime.now().toUtc().subtract(const Duration(minutes: 1)));
      await storeTokens(access: expired, refresh: 'refresh');
      session.refreshTransport =
          (_) async => const RefreshOutcome.success(accessToken: 'fresh-access');

      expect(await session.validAccessToken(), 'fresh-access');
    });

    test('returns null when there is no session at all', () async {
      expect(await session.validAccessToken(), isNull);
    });

    test('returns null when the refresh is rejected', () async {
      final expired =
          jwtExpiringAt(DateTime.now().toUtc().subtract(const Duration(minutes: 1)));
      await storeTokens(access: expired, refresh: 'refresh');
      session.refreshTransport = (_) async => const RefreshOutcome.rejected();

      expect(await session.validAccessToken(), isNull);
    });
  });

  group('endSession', () {
    test('clears credentials but leaves other preferences alone', () async {
      final prefs = await SharedPreferences.getInstance();
      await storeTokens(access: 'a', refresh: 'r');
      await prefs.setString(SharedPrefKeys.userId, 'u1');
      await prefs.setString('themeMode', 'dark');

      await session.endSession(navigateToLogin: false);

      expect(prefs.getString(SharedPrefKeys.userToken), isNull);
      expect(prefs.getString(SharedPrefKeys.refreshToken), isNull);
      expect(prefs.getString(SharedPrefKeys.userId), isNull);
      expect(prefs.getString('themeMode'), 'dark');
    });

    test('runs every teardown hook', () async {
      final ran = <String>[];
      session.sessionEndHooks
        ..add(() => ran.add('notifications'))
        ..add(() => ran.add('chats'));

      await session.endSession(navigateToLogin: false);

      expect(ran, ['notifications', 'chats']);
    });

    test('a throwing hook does not block the rest of the teardown', () async {
      final ran = <String>[];
      session.sessionEndHooks
        ..add(() => throw StateError('cubit already gone'))
        ..add(() => ran.add('chats'));

      await session.endSession(navigateToLogin: false);

      expect(ran, ['chats']);
    });

    test('hasStoredSession needs both tokens', () async {
      expect(await session.hasStoredSession(), isFalse);

      await storeTokens(access: 'a');
      expect(await session.hasStoredSession(), isFalse);

      await storeTokens(refresh: 'r');
      expect(await session.hasStoredSession(), isTrue);
    });
  });
}
