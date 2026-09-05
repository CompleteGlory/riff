import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/networks/connectivity_service.dart';

/// See connectivity_service_test.md for what this covers and why.
void main() {
  late ConnectivityService service;

  setUp(() {
    ConnectivityService.resetInstanceForTest();
    service = ConnectivityService.instance;
  });

  tearDown(() => ConnectivityService.resetInstanceForTest());

  DioException dio(DioExceptionType type, {Response<dynamic>? response,
      Object? error}) =>
      DioException(
        requestOptions: RequestOptions(path: '/api/posts'),
        type: type,
        response: response,
        error: error,
      );

  /// Lets an in-flight probe complete. The status now settles a microtask
  /// after a failure rather than synchronously with it.
  Future<void> pumpProbe() => Future<void>.delayed(Duration.zero);

  Response<dynamic> response(int status) => Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/posts'),
        statusCode: status,
      );

  group('classifying failures', () {
    // The distinction the whole feature rests on: a 500 means the server is
    // there and unhappy, which is not the same as having no connection, and
    // showing "you're offline" for it would be a lie.
    test('a server response is never treated as being offline', () {
      expect(
        ConnectivityService.isNetworkFailure(
          dio(DioExceptionType.badResponse, response: response(500)),
        ),
        isFalse,
      );
      expect(
        ConnectivityService.isNetworkFailure(
          dio(DioExceptionType.badResponse, response: response(401)),
        ),
        isFalse,
      );
    });

    test('transport failures are treated as being offline', () {
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(ConnectivityService.isNetworkFailure(dio(type)), isTrue,
            reason: '$type should count as offline');
      }
    });

    // Dio funnels raw socket errors through `unknown`, so the type alone isn't
    // enough to tell a dead network from a parsing bug.
    test('an unknown error wrapping a SocketException counts as offline', () {
      expect(
        ConnectivityService.isNetworkFailure(
          dio(DioExceptionType.unknown,
              error: const SocketException('no route to host')),
        ),
        isTrue,
      );
    });

    test('a cancelled request is not an offline signal', () {
      expect(
        ConnectivityService.isNetworkFailure(dio(DioExceptionType.cancel)),
        isFalse,
      );
    });
  });

  group('status transitions', () {
    /// A probe that always answers [reachable], so a test never touches the
    /// network. Every transport failure now consults one.
    void stubProbe(bool reachable) =>
        service.probe = () async => reachable;

    test('starts online so nothing shows a banner before the first request',
        () {
      expect(service.isOnline, isTrue);
    });

    test('one failed request does not by itself go offline', () async {
      // The reported bug: the banner appeared at launch on a good connection.
      // A cold server answering slowly, or any non-network exception with no
      // response, looks exactly like a dead network from here — so a single
      // failure is a suspicion and the probe settles it.
      stubProbe(true);

      service.reportDioError(dio(DioExceptionType.connectionError));
      await pumpProbe();

      expect(service.isOnline, isTrue);
    });

    test('a failed request goes offline once a probe agrees', () async {
      stubProbe(false);
      final seen = <bool>[];
      final sub = service.onStatusChanged.listen(seen.add);

      service.reportDioError(dio(DioExceptionType.connectionError));
      await pumpProbe();
      expect(service.isOffline, isTrue);

      service.reportReachable();
      expect(service.isOnline, isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(seen, [false, true]);
      await sub.cancel();
    });

    test('a slow response is not mistaken for a dead network', () async {
      // receiveTimeout means the server accepted the connection and then took
      // too long. The transport demonstrably worked; the server was slow.
      stubProbe(true);

      service.reportDioError(dio(DioExceptionType.receiveTimeout));
      await pumpProbe();

      expect(service.isOnline, isTrue);
    });

    test('only transitions are emitted, never repeats', () async {
      stubProbe(false);
      final seen = <bool>[];
      final sub = service.onStatusChanged.listen(seen.add);

      service.reportDioError(dio(DioExceptionType.connectionError));
      await pumpProbe();
      service.reportDioError(dio(DioExceptionType.connectionTimeout));
      await pumpProbe();
      service.reportReachable();
      service.reportReachable();

      await Future<void>.delayed(Duration.zero);
      expect(seen, [false, true]);
      await sub.cancel();
    });

    test('a real response outranks a probe still in flight', () async {
      // The probe from a failed request can land *after* the next request has
      // succeeded. Applying it then would drag a working app offline — which
      // is how the first attempt at this fix broke an existing test.
      final probeStarted = Completer<void>();
      final probeAnswer = Completer<bool>();
      service.probe = () {
        if (!probeStarted.isCompleted) probeStarted.complete();
        return probeAnswer.future;
      };

      service.reportDioError(dio(DioExceptionType.connectionError));
      await probeStarted.future;

      // Better evidence arrives while the probe is still running.
      service.reportReachable();
      expect(service.isOnline, isTrue);

      probeAnswer.complete(false);
      await pumpProbe();

      expect(service.isOnline, isTrue,
          reason: 'a stale probe must not override a real response');
    });

    // An HTTP error proves the server answered, so it should clear an offline
    // state rather than leave the banner up until the next successful request.
    test('a server error while offline restores the online state', () async {
      stubProbe(false);
      service.reportDioError(dio(DioExceptionType.connectionError));
      await pumpProbe();
      expect(service.isOffline, isTrue);

      service.reportDioError(
        dio(DioExceptionType.badResponse, response: response(404)),
      );
      expect(service.isOnline, isTrue);
    });

    test('does not probe again for each failure while already offline',
        () async {
      var probes = 0;
      service.probe = () async {
        probes++;
        return false;
      };

      service.reportDioError(dio(DioExceptionType.connectionError));
      await pumpProbe();
      expect(probes, 1);

      // Offline already; the backoff timer owns recovery from here, and
      // probing per failed request would hammer a host that is not answering.
      service.reportDioError(dio(DioExceptionType.connectionError));
      service.reportDioError(dio(DioExceptionType.connectionTimeout));
      await pumpProbe();

      expect(probes, 1);
    });

    test('the notifier mirrors the status for widgets', () async {
      stubProbe(false);
      expect(service.status.value, isTrue);

      service.reportDioError(dio(DioExceptionType.connectionError));
      await pumpProbe();

      expect(service.status.value, isFalse);
    });
  });

  group('checkNow', () {
    test('a failing probe reports offline', () async {
      service.probe = () async => false;
      expect(await service.checkNow(), isFalse);
      expect(service.isOffline, isTrue);
    });

    test('a succeeding probe reports online', () async {
      service.reportDioError(dio(DioExceptionType.connectionError));
      service.probe = () async => true;

      expect(await service.checkNow(), isTrue);
      expect(service.isOnline, isTrue);
    });

    test('concurrent callers share one probe', () async {
      var probes = 0;
      service.probe = () async {
        probes++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return true;
      };

      await Future.wait([service.checkNow(), service.checkNow()]);
      expect(probes, 1);
    });
  });
}
