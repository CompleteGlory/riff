import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart' hide Headers;
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/home/account_settings/data/repos/delete_account_repo.dart';

import 'delete_account_repo_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late MockApiService mockApiService;
  late DeleteAccountRepo repo;

  HttpResponse<dynamic> okResponse() {
    final response = Response<dynamic>(
      requestOptions: RequestOptions(path: '/api/users/me'),
      statusCode: 200,
      data: {'deleted': true},
    );
    return HttpResponse<dynamic>(response.data, response);
  }

  setUp(() {
    mockApiService = MockApiService();
    repo = DeleteAccountRepo(mockApiService);
  });

  group('DeleteAccountRepo.deleteAccount', () {
    test('sends only the password for a password account', () async {
      when(mockApiService.deleteAccount(any))
          .thenAnswer((_) async => okResponse());

      final result = await repo.deleteAccount(password: 'hunter2');

      expect(result, isA<Success<void>>());
      final body = verify(mockApiService.deleteAccount(captureAny))
          .captured
          .single as Map<String, dynamic>;
      expect(body, {'password': 'hunter2'});
      // Sending a stray null `confirmUsername` would read on the server as an
      // OAuth confirmation attempt on an account that has a password.
      expect(body.containsKey('confirmUsername'), isFalse);
    });

    test('sends only the username for an OAuth account', () async {
      when(mockApiService.deleteAccount(any))
          .thenAnswer((_) async => okResponse());

      final result = await repo.deleteAccount(confirmUsername: 'magd');

      expect(result, isA<Success<void>>());
      final body = verify(mockApiService.deleteAccount(captureAny))
          .captured
          .single as Map<String, dynamic>;
      expect(body, {'confirmUsername': 'magd'});
    });

    test('surfaces a rejected confirmation as a failure with its status',
        () async {
      when(mockApiService.deleteAccount(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/users/me'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/api/users/me'),
            statusCode: 401,
            data: {'message': 'Incorrect password'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repo.deleteAccount(password: 'wrong');

      expect(result, isA<Failure<void>>());
      // The cubit keys "wrong password" off the 401, so it has to survive the
      // trip through ApiErrorHandler.
      expect((result as Failure<void>).apiErrorModel.statusCode, 401);
    });

    test('surfaces a transport failure as a failure', () async {
      when(mockApiService.deleteAccount(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/users/me'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repo.deleteAccount(password: 'hunter2');

      expect(result, isA<Failure<void>>());
    });
  });
}
