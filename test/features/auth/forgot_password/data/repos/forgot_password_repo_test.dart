import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart' hide Headers;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/auth/forgot_password/data/models/request_otp_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/reset_password_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/verify_otp_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/repos/forgot_pasword_repo.dart';

import 'forgot_password_repo_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late MockApiService mockApiService;
  late ForgotPasswordRepo repo;

  HttpResponse<void> buildVoidResponse({dynamic data, int statusCode = 200}) {
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/auth/otp'),
      statusCode: statusCode,
      data: data,
    );
    return HttpResponse<void>(null, response);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockApiService = MockApiService();
    repo = ForgotPasswordRepo(mockApiService);
  });

  group('requestOtp', () {
    test('returns success with the reset token when the body has one',
        () async {
      when(mockApiService.requestOtp(any)).thenAnswer(
        (_) async => buildVoidResponse(data: {'reset_token': 'otp-reset-tok'}),
      );

      final result = await repo.requestOtp(RequestOtpRequestBody(email: 'a@b.com'));

      expect(result, isA<Success<String?>>());
      result.when(
        success: (token) => expect(token, 'otp-reset-tok'),
        failure: (_) => fail('expected success'),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPrefKeys.userToken), 'otp-reset-tok');
    });

    test('accepts the camelCase resetToken key too', () async {
      when(mockApiService.requestOtp(any)).thenAnswer(
        (_) async => buildVoidResponse(data: {'resetToken': 'camel-tok'}),
      );

      final result = await repo.requestOtp(RequestOtpRequestBody(email: 'a@b.com'));

      result.when(
        success: (token) => expect(token, 'camel-tok'),
        failure: (_) => fail('expected success'),
      );
    });

    test('returns success with null token when the body has none', () async {
      when(mockApiService.requestOtp(any)).thenAnswer(
        (_) async => buildVoidResponse(data: {'unrelated': true}),
      );

      final result = await repo.requestOtp(RequestOtpRequestBody(email: 'a@b.com'));

      result.when(
        success: (token) => expect(token, isNull),
        failure: (_) => fail('expected success'),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPrefKeys.userToken), isNull);
    });

    test('returns failure when the API call throws', () async {
      when(mockApiService.requestOtp(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/otp'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repo.requestOtp(RequestOtpRequestBody(email: 'a@b.com'));

      expect(result, isA<Failure<String?>>());
    });
  });

  group('verifyOtp', () {
    test('returns success with the reset token when the body has one',
        () async {
      when(mockApiService.verifyOtp(any)).thenAnswer(
        (_) async => buildVoidResponse(data: {'reset_token': 'verify-tok'}),
      );

      final result = await repo.verifyOtp(
        VerifyOtpRequestBody(email: 'a@b.com', otp: '123456'),
      );

      result.when(
        success: (token) => expect(token, 'verify-tok'),
        failure: (_) => fail('expected success'),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPrefKeys.userToken), 'verify-tok');
    });

    test('returns success with null token when the body has none', () async {
      when(mockApiService.verifyOtp(any)).thenAnswer(
        (_) async => buildVoidResponse(data: null),
      );

      final result = await repo.verifyOtp(
        VerifyOtpRequestBody(email: 'a@b.com', otp: '123456'),
      );

      result.when(
        success: (token) => expect(token, isNull),
        failure: (_) => fail('expected success'),
      );
    });

    test('returns failure when the API call throws', () async {
      when(mockApiService.verifyOtp(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/otp/verify'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/otp/verify'),
            statusCode: 400,
            data: {'message': 'Invalid OTP'},
          ),
        ),
      );

      final result = await repo.verifyOtp(
        VerifyOtpRequestBody(email: 'a@b.com', otp: '000000'),
      );

      expect(result, isA<Failure<String?>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (error) => expect(error.message, 'Invalid OTP'),
      );
    });
  });

  group('resetPassword', () {
    test('returns success', () async {
      when(mockApiService.resetPassword(any)).thenAnswer(
        (_) async => buildVoidResponse(),
      );

      final result = await repo.resetPassword(
        ResetPasswordRequestBody(resetToken: 'tok', newPassword: 'NewPass123'),
      );

      expect(result, isA<Success<void>>());
    });

    test('returns failure when the API call throws', () async {
      when(mockApiService.resetPassword(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/reset-password'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await repo.resetPassword(
        ResetPasswordRequestBody(resetToken: 'tok', newPassword: 'NewPass123'),
      );

      expect(result, isA<Failure<void>>());
    });
  });
}
