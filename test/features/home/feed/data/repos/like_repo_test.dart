import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/home/feed/data/repos/like_repo.dart';
import 'package:riff/features/home/follow/data/models/follow_user.dart';

import 'like_repo_test.mocks.dart';

/// See like_repo_test.md for what this covers and why.
@GenerateMocks([ApiService, Dio])
void main() {
  late MockApiService api;
  late MockDio dio;
  late LikeRepo repo;

  setUp(() {
    api = MockApiService();
    dio = MockDio();
    repo = LikeRepo(api, dio);
  });

  Response<dynamic> response(dynamic data) => Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/posts/7/likes'),
        statusCode: 200,
        data: data,
      );

  List<FollowUser> unwrap(ApiResult<List<FollowUser>> result) => result.when(
        success: (users) => users,
        failure: (e) => throw StateError('expected success, got ${e.message}'),
      );

  group('getPostLikers', () {
    test('requests the post\'s likes endpoint', () async {
      when(dio.get(any)).thenAnswer((_) async => response(<dynamic>[]));

      await repo.getPostLikers(7);

      verify(dio.get('/api/posts/7/likes')).called(1);
    });

    test('parses the users and their follow status', () async {
      when(dio.get(any)).thenAnswer((_) async => response([
            {
              'id': 'u1',
              'full_name': 'Mo Salah',
              'username': 'mo',
              'profile_image_url': 'https://cdn/mo.jpg',
              'is_private': false,
              'follow_status': 'following',
            },
            {
              'id': 'u2',
              'full_name': 'Sara',
              'username': 'sara',
              'profile_image_url': null,
              'is_private': true,
              'follow_status': 'pending',
            },
          ]));

      final users = unwrap(await repo.getPostLikers(7));

      expect(users.map((u) => u.username), ['mo', 'sara']);
      // The follow status comes down with the list on purpose — it saves a
      // request per row for the follow button beside each name.
      expect(users.first.followStatus, 'following');
      expect(users.last.followStatus, 'pending');
      expect(users.last.isPrivate, isTrue);
      expect(users.last.profileImageUrl, isNull);
    });

    test('a post with no likes is an empty list, not a failure', () async {
      when(dio.get(any)).thenAnswer((_) async => response(<dynamic>[]));

      expect(unwrap(await repo.getPostLikers(7)), isEmpty);
    });

    test('a network failure comes back as a failure result', () async {
      when(dio.get(any)).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/posts/7/likes'),
        type: DioExceptionType.connectionError,
      ));

      final result = await repo.getPostLikers(7);

      expect(
        result.when(success: (_) => 'success', failure: (_) => 'failure'),
        'failure',
      );
    });

    // The screen renders whatever comes back; a shape it can't read must not
    // reach it as a half-parsed list.
    test('an unexpected body shape is a failure, not a crash', () async {
      when(dio.get(any))
          .thenAnswer((_) async => response({'unexpected': 'shape'}));

      final result = await repo.getPostLikers(7);

      expect(
        result.when(success: (_) => 'success', failure: (_) => 'failure'),
        'failure',
      );
    });
  });
}
