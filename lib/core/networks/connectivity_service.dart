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

  // ── Reporting from the network layer ──────────────────────────────────────

  /// A request completed — whatever else happened, we can reach the server.
  void reportReachable() => _setOnline(true);

  /// Classifies [error] and updates the status accordingly.
  void reportDioError(DioException error) {
    if (isNetworkFailure(error)) {
      _setOnline(false);
    } else {
      // The server produced a response, so the transport is healthy even
      // though this particular request failed.
      _setOnline(true);
    }
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
    final reachable = await (probe ?? _defaultProbe)();
    _setOnline(reachable);
    return reachable;
  }

  Future<bool> _defaultProbe() async {
    try {
      final host = Uri.parse(ApiConstants.apiBASEURL).host;
      final addresses = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 5));
      return addresses.isNotEmpty && addresses.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
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
