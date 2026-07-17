import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/auth/signup/data/models/signup_request_body.dart';
import 'package:riff/features/auth/signup/data/repos/signup_repo.dart';

import 'signup_repo_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late MockApiService mockApiService;
  late SignupRepo repo;

  final requestBody = SignupRequestBody(
    email: 'user@example.com',
    password: 'Password123',
    fullName: 'Test User',
    username: 'testuser',
    instruments: const ['guitar'],
    genres: const ['rock'],
  );

  setUp(() {
    mockApiService = MockApiService();
    repo = SignupRepo(mockApiService);
  });

  test('returns success when the API call completes', () async {
    when(mockApiService.signUp(any)).thenAnswer((_) async {});

    final result = await repo.signUp(requestBody);

    expect(result, isA<Success<void>>());
    final captured =
        verify(mockApiService.signUp(captureAny)).captured.single
            as SignupRequestBody;
    expect(captured.email, 'user@example.com');
    expect(captured.username, 'testuser');
    expect(captured.instruments, ['guitar']);
    expect(captured.genres, ['rock']);
  });

  test('returns failure with the server message when signup is rejected',
      () async {
    when(mockApiService.signUp(any)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/signup'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/signup'),
          statusCode: 409,
          data: {'statusCode': 409, 'message': 'Username already taken'},
        ),
      ),
    );

    final result = await repo.signUp(requestBody);

    expect(result, isA<Failure<void>>());
    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) {
        expect(error.statusCode, 409);
        expect(error.message, 'Username already taken');
      },
    );
  });

  test('returns failure when the API call throws a connection error',
      () async {
    when(mockApiService.signUp(any)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/signup'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await repo.signUp(requestBody);

    expect(result, isA<Failure<void>>());
  });
}
