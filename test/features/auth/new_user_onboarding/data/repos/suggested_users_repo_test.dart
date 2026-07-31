import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/new_user_onboarding/data/repos/suggested_users_repo.dart';

import 'suggested_users_repo_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late SuggestedUsersRepo repo;

  Map<String, dynamic> userJson(String id) => {
        'id': id,
        'full_name': 'User $id',
        'username': 'user$id',
        'is_private': false,
      };

  setUp(() {
    mockDio = MockDio();
    repo = SuggestedUsersRepo(mockDio);
  });

  group('getSuggested', () {
    test('parses a bare list response', () async {
      when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
          .thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/discover'),
          statusCode: 200,
          data: [userJson('1'), userJson('2')],
        ),
      );

      final result = await repo.getSuggested();

      expect(result, isA<Success<List<dynamic>>>());
      result.when(
        success: (users) => expect(users.map((u) => u.id), ['1', '2']),
        failure: (_) => fail('expected success'),
      );
    });

    test('parses a { data: [...] } wrapped response', () async {
      when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
          .thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/discover'),
          statusCode: 200,
          data: {
            'data': [userJson('3')],
          },
        ),
      );

      final result = await repo.getSuggested();

      result.when(
        success: (users) => expect(users.single.id, '3'),
        failure: (_) => fail('expected success'),
      );
    });

    test('returns an empty list for an unrecognized body shape', () async {
      when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
          .thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/discover'),
          statusCode: 200,
          data: 'unexpected',
        ),
      );

      final result = await repo.getSuggested();

      result.when(
        success: (users) => expect(users, isEmpty),
        failure: (_) => fail('expected success'),
      );
    });

    test('returns failure when the request throws', () async {
      when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
          .thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/discover'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repo.getSuggested();

      expect(result, isA<Failure<List<dynamic>>>());
    });
  });

}
