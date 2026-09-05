import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riff/core/networks/api_constants.dart';

/// Probes whether the API host is reachable. Swappable so tests never touch
/// the network.
typedef ReachabilityProbe = Future<bool> Function();

/// App-wide "are we actually online?" signal.
///
/// Deliberately plugin-free: the answer is derived from the two things the app
/// already knows for certain — how real requests behave — plus a cheap DNS
/// probe for the API host to notice when connectivity comes back.
///
/// * Every Dio response marks the app online (a reply proves reachability).
/// * Every *transport-level* Dio failure (connection error, timeout, unknown
///   socket error) marks it offline. HTTP failures — 401, 404, 500 — do not:
///   the server answered, so the network is fine.
/// * While offline, a probe re-runs on a backoff until it succeeds, so the
///   banner clears and the caches refresh without the user doing anything.
///
/// Callers that need to react (banner, cubits refreshing stale caches) listen
/// to [onStatusChanged], which only fires on an actual transition.
class ConnectivityService {
  ConnectivityService._();

  static ConnectivityService instance = ConnectivityService._();

  /// Replaces the singleton. Tests only.
  @visibleForTesting
  static void setInstanceForTest(ConnectivityService service) =>
      instance = service;

  /// Restores the real singleton. Tests only.
  @visibleForTesting
  static void resetInstanceForTest() {
    instance._recheckTimer?.cancel();
    instance = ConnectivityService._();
  }

  /// First recheck delay after going offline; doubles up to [maxBackoff].
  static const Duration minBackoff = Duration(seconds: 3);
  static const Duration maxBackoff = Duration(seconds: 30);

  final _controller = StreamController<bool>.broadcast();

  /// Emits `true` when connectivity returns and `false` when it is lost.
  /// Only transitions are emitted, never repeats of the current value.
  Stream<bool> get onStatusChanged => _controller.stream;

  /// Mirrors [isOnline] for widgets that want to rebuild without a StreamBuilder.
  final ValueNotifier<bool> status = ValueNotifier<bool>(true);

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  /// Overridable probe — defaults to a DNS lookup of the API host.
  ReachabilityProbe? probe;

  Timer? _recheckTimer;
  Duration _backoff = minBackoff;
  Future<bool>? _inFlightProbe;

  /// Bumped by every *definitive* report — a real response from the server.
  ///
  /// A probe that started before the bump is answering a question that has
  /// since been settled by better evidence, so it must not apply its result.
  /// Without this, a probe begun on a failed request can land after the next
  /// request has already succeeded and drag the app back offline. The same
  /// epoch trick `NotificationsCubit` uses against a poll that overwrites a
  /// local change.
  int _epoch = 0;

  // ── Reporting from the network layer ──────────────────────────────────────

  /// A request completed — whatever else happened, we can reach the server.
  ///
  /// This is proof, so it also invalidates any probe still in flight.
  void reportReachable() {
    _epoch++;
    _setOnline(true);
  }

  /// Classifies [error] and updates the status accordingly.
  ///
  /// A transport failure is a **suspicion, not a verdict**. Declaring the
  /// whole app offline on one failed request is how the banner appeared at
  /// launch on a perfectly good connection: a cold Railway container is slow
  /// to answer its first request, a `receiveTimeout` looks identical to a dead
  /// network from here, and `unknown` with no response catches any non-network
  /// exception thrown along the way. So the failure triggers a probe and the
  /// probe decides.
  ///
  /// This mirrors what `SessionManager` already learned the hard way: one
  /// rejection is not proof, and acting on it alone produced exactly this
  /// class of false positive.
  void reportDioError(DioException error) {
    if (!isNetworkFailure(error)) {
      // The server produced a response, so the transport is healthy even
      // though this particular request failed. That is conclusive, and it
      // clears an offline state immediately — and outranks any probe still
      // running.
      _epoch++;
      _setOnline(true);
      return;
    }
    // Already offline: the backoff timer owns recovery, and probing per failed
    // request while offline would hammer the host.
    if (!_isOnline) return;
    unawaited(checkNow());
  }

  /// Whether [error] is a transport failure (no answer from the server) rather
  /// than an HTTP error the server deliberately returned.
  static bool isNetworkFailure(Object? error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return true;
        case DioExceptionType.unknown:
          // Dio funnels raw SocketExceptions through `unknown`.
          return error.error is SocketException ||
              error.error is HandshakeException ||
              error.response == null;
        case DioExceptionType.badResponse:
        case DioExceptionType.cancel:
        case DioExceptionType.badCertificate:
          return false;
      }
    }
    return error is SocketException || error is HandshakeException;
  }

  // ── Probing ───────────────────────────────────────────────────────────────

  /// Runs a reachability probe now and updates the status from the result.
  /// Concurrent callers share one probe.
  Future<bool> checkNow() {
    return _inFlightProbe ??= _runProbe().whenComplete(() {
      _inFlightProbe = null;
    });
  }

  Future<bool> _runProbe() async {
    final startedAt = _epoch;
    final reachable = await (probe ?? _defaultProbe)();
    // A real response arrived while this was running. It is better evidence
    // than a probe, and it has already been applied.
    if (startedAt != _epoch) return reachable;
    _setOnline(reachable);
    return reachable;
  }

  /// Asks the API host for anything at all.
  ///
  /// This used to be a DNS lookup, which answers a different question. A
  /// resolved name does not mean the server is reachable, and — the reason the
  /// banner appeared at launch — a failed lookup does not mean the device is
  /// offline: DNS is routinely unavailable for a moment on a device that has
  /// just woken, behind a VPN, or on a network still coming up.
  ///
  /// **Any HTTP status counts as reachable**, including 401 and 404. The
  /// question is whether packets reach the server and come back, not whether
  /// it liked the request. Only a transport-level exception means offline.
  ///
  /// Deliberately a bare [HttpClient] rather than the app's Dio: routing it
  /// through the interceptor would report its own outcome back into this
  /// service and probe recursively.
  Future<bool> _defaultProbe() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client
          .headUrl(Uri.parse(ApiConstants.apiBASEURL))
          .timeout(const Duration(seconds: 6));
      final response = await request.close().timeout(const Duration(seconds: 6));
      await response.drain<void>();
      return true;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  // ── Status transitions ────────────────────────────────────────────────────

  void _setOnline(bool online) {
    if (online) {
      _recheckTimer?.cancel();
      _recheckTimer = null;
      _backoff = minBackoff;
    } else {
      _scheduleRecheck();
    }

    if (_isOnline == online) return;
    _isOnline = online;
    status.value = online;
    if (!_controller.isClosed) _controller.add(online);
    debugPrint('ConnectivityService: ${online ? 'online' : 'offline'}');
  }

  void _scheduleRecheck() {
    if (_recheckTimer != null) return;
    _recheckTimer = Timer(_backoff, () {
      _recheckTimer = null;
      _backoff = _backoff * 2 > maxBackoff ? maxBackoff : _backoff * 2;
      checkNow();
    });
  }

  @visibleForTesting
  Future<void> dispose() async {
    _recheckTimer?.cancel();
    _recheckTimer = null;
    await _controller.close();
  }
}
