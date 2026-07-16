import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart' hide Headers;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/auth/login/data/models/login_request_body.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/login/data/repos/login_repo.dart';

import 'login_repo_test.mocks.dart';

@GenerateMocks([ApiService])

void main() {
  late MockApiService mockApiService;
  late LoginRepo loginRepo;

  HttpResponse<dynamic> buildResponse({
    required Map<String, dynamic> data,
    List<String>? setCookieHeaders,
    int statusCode = 200,
  }) {
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/auth/login'),
      statusCode: statusCode,
      data: data,
      headers: Headers.fromMap(
        setCookieHeaders != null ? {'set-cookie': setCookieHeaders} : {},
      ),
    );
    return HttpResponse<dynamic>(data, response);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockApiService = MockApiService();
    loginRepo = LoginRepo(mockApiService);
  });

  group('LoginRepo.login', () {
    final requestBody = LoginRequestBody(
      email: 'user@example.com',
      password: 'Password123',
    );

    test('returns success and persists tokens + user id from cookies',
        () async {
      when(mockApiService.login(any)).thenAnswer(
        (_) async => buildResponse(
          data: {
            'user': {
              'id': 'u1',
              'email': 'user@example.com',
              'full_name': 'Test User',
              'username': 'testuser',
            },
          },
          setCookieHeaders: [
            'AccessToken=access-123; Path=/; HttpOnly',
            'RefreshToken=refresh-456; Path=/; HttpOnly',
          ],
        ),
      );

      final result = await loginRepo.login(requestBody);

      expect(result, isA<Success<LoginResponse>>());
      result.when(
        success: (data) {
          expect(data.user.id, 'u1');
          expect(data.user.email, 'user@example.com');
        },
        failure: (_) => fail('expected success'),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPrefKeys.userToken), 'access-123');
      expect(prefs.getString(SharedPrefKeys.refreshToken), 'refresh-456');
      expect(prefs.getString(SharedPrefKeys.userId), 'u1');
    });

    test('falls back to JWT payload when user object is absent', () async {
      // sub=abc, email=fallback@jwt.com, base64url-encoded, unsigned
      const jwt =
          'header.eyJzdWIiOiJhYmMiLCJlbWFpbCI6ImZhbGxiYWNrQGp3dC5jb20ifQ.sig';
      when(mockApiService.login(any)).thenAnswer(
        (_) async => buildResponse(
          data: <String, dynamic>{},
          setCookieHeaders: [
            'AccessToken=$jwt; Path=/',
            'RefreshToken=refresh-jwt-fallback; Path=/',
          ],
        ),
      );

      final result = await loginRepo.login(requestBody);

      expect(result, isA<Success<LoginResponse>>());
      result.when(
        success: (data) {
          expect(data.user.id, 'abc');
          expect(data.user.email, 'fallback@jwt.com');
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('returns failure when the API call throws a DioException', () async {
      when(mockApiService.login(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await loginRepo.login(requestBody);

      expect(result, isA<Failure<LoginResponse>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (error) =>
            expect(error.message, 'Connection to server failed'),
      );
    });

    test('returns failure with server message on bad response', () async {
      when(mockApiService.login(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
            data: {'statusCode': 401, 'message': 'Invalid credentials'},
          ),
        ),
      );

      final result = await loginRepo.login(requestBody);

      expect(result, isA<Failure<LoginResponse>>());
      result.when(
        success: (_) => fail('expected failure'),
        failure: (error) {
          expect(error.statusCode, 401);
          expect(error.message, 'Invalid credentials');
        },
      );
    });

    test('does not crash and still succeeds when no cookies are present',
        () async {
      when(mockApiService.login(any)).thenAnswer(
        (_) async => buildResponse(
          data: {
            'user': {
              'id': 'u2',
              'email': 'nouser@example.com',
              'full_name': 'No Cookie',
              'username': 'nocookie',
            },
          },
        ),
      );

      final result = await loginRepo.login(requestBody);

      expect(result, isA<Success<LoginResponse>>());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPrefKeys.userToken), isNull);
    });
  });

  group('LoginRepo.loginWithGoogle', () {
    test('propagates isNewUser=true from the raw response body', () async {
      when(mockApiService.googleLogin(any)).thenAnswer(
        (_) async => buildResponse(
          data: {
            'isNewUser': true,
            'user': {
              'id': 'g1',
              'email': 'g@example.com',
              'full_name': 'Google User',
              'username': 'googleuser',
            },
          },
          setCookieHeaders: [
            'AccessToken=gtoken; Path=/',
            'RefreshToken=refresh-gtoken; Path=/',
          ],
        ),
      );

      final result = await loginRepo.loginWithGoogle('id-token');

      expect(result, isA<Success<LoginResponse>>());
      result.when(
        success: (data) {
          expect(data.isNewUser, isTrue);
          expect(data.user.id, 'g1');
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('propagates isNewUser=false for an existing Google account',
        () async {
      when(mockApiService.googleLogin(any)).thenAnswer(
        (_) async => buildResponse(
          data: {
            'isNewUser': false,
            'user': {
              'id': 'g2',
              'email': 'existing@example.com',
              'full_name': 'Existing User',
              'username': 'existinguser',
            },
          },
          setCookieHeaders: [
            'AccessToken=gtoken2; Path=/',
            'RefreshToken=refresh-gtoken2; Path=/',
          ],
        ),
      );

      final result = await loginRepo.loginWithGoogle('id-token');

      expect(result, isA<Success<LoginResponse>>());
      result.when(
        success: (data) => expect(data.isNewUser, isFalse),
        failure: (_) => fail('expected success'),
      );
    });

    test('returns failure when the Google API call throws', () async {
      when(mockApiService.googleLogin(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/google'),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      final result = await loginRepo.loginWithGoogle('bad-token');

      expect(result, isA<Failure<LoginResponse>>());
    });
  });
}
