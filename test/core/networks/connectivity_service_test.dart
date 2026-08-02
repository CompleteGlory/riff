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
    test('starts online so nothing shows a banner before the first request',
        () {
      expect(service.isOnline, isTrue);
    });

    test('a transport failure goes offline and a response comes back', () async {
      final seen = <bool>[];
      final sub = service.onStatusChanged.listen(seen.add);

      service.reportDioError(dio(DioExceptionType.connectionError));
      expect(service.isOffline, isTrue);

      service.reportReachable();
      expect(service.isOnline, isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(seen, [false, true]);
      await sub.cancel();
    });

    test('only transitions are emitted, never repeats', () async {
      final seen = <bool>[];
      final sub = service.onStatusChanged.listen(seen.add);

      service.reportDioError(dio(DioExceptionType.connectionError));
      service.reportDioError(dio(DioExceptionType.connectionTimeout));
      service.reportReachable();
      service.reportReachable();

      await Future<void>.delayed(Duration.zero);
      expect(seen, [false, true]);
      await sub.cancel();
    });

    // An HTTP error proves the server answered, so it should clear an offline
    // state rather than leave the banner up until the next successful request.
    test('a server error while offline restores the online state', () {
      service.reportDioError(dio(DioExceptionType.connectionError));
      expect(service.isOffline, isTrue);

      service.reportDioError(
        dio(DioExceptionType.badResponse, response: response(404)),
      );
      expect(service.isOnline, isTrue);
    });

    test('the notifier mirrors the status for widgets', () {
      expect(service.status.value, isTrue);
      service.reportDioError(dio(DioExceptionType.connectionError));
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
