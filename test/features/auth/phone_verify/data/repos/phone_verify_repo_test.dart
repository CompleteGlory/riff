import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/phone_verify/data/repos/phone_verify_repo.dart';

import 'phone_verify_repo_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late PhoneVerifyRepo repo;

  setUp(() {
    mockDio = MockDio();
    repo = PhoneVerifyRepo(mockDio);
  });

  Response<dynamic> okResponse({int statusCode = 200}) => Response(
        requestOptions: RequestOptions(path: '/phone/otp'),
        statusCode: statusCode,
      );

  group('sendOtp', () {
    test('strips non-digit characters before posting and returns success',
        () async {
      when(mockDio.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => okResponse());

      final result = await repo.sendOtp('+20 100-123-4567');

      expect(result, isA<Success<void>>());
      final captured = verify(
        mockDio.post(any, data: captureAnyNamed('data')),
      ).captured.single as Map<String, dynamic>;
      expect(captured['phone_number'], '201001234567');
    });

    test('returns failure when the request throws', () async {
      when(mockDio.post(any, data: anyNamed('data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/phone/otp'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repo.sendOtp('01001234567');

      expect(result, isA<Failure<void>>());
    });
  });

  group('verifyOtp', () {
    test('posts the normalized phone number and otp, returns success',
        () async {
      when(mockDio.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => okResponse());

      final result = await repo.verifyOtp('01001234567', '123456');

      expect(result, isA<Success<void>>());
      final captured = verify(
        mockDio.post(any, data: captureAnyNamed('data')),
      ).captured.single as Map<String, dynamic>;
      expect(captured['phone_number'], '01001234567');
      expect(captured['otp'], '123456');
    });

    test('returns failure with the server message on a bad response',
        () async {
      when(mockDio.post(any, data: anyNamed('data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/phone/otp/verify'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/phone/otp/verify'),
            statusCode: 400,
            data: {'message': 'Invalid OTP'},
          ),
        ),
      );

      final result = await repo.verifyOtp('01001234567', '000000');

      expect(result, isA<Failure<void>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (error) => expect(error.message, 'Invalid OTP'),
      );
    });
  });
}
