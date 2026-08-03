import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/cache/cache_keys.dart';
import 'package:riff/core/cache/offline_cache.dart';
import 'package:riff/core/logic/post_events.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/models/author.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/profile/data/repos/profile_repo.dart';
import 'package:riff/features/home/profile/logic/cubit/profile_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_cubit_test.mocks.dart';

/// See profile_cubit_test.md for what this covers and why.
@GenerateMocks([ProfileRepo])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const myId = 'me-1';
  const otherId = 'someone-else';

  late MockProfileRepo repo;
  late Directory root;
  late OfflineCache cache;
  late ProfileCubit cubit;

  Post post(int id) => Post(
        id: id,
        author: Author(id: myId, fullName: 'Mo', username: 'mo'),
        content: 'post $id',
        createdAt: '2026-08-01T10:00:00Z',
        updatedAt: '2026-08-01T10:00:00Z',
        isLiked: false,
        likesCount: '0',
      );

  ApiResult<List<Post>> offline() =>
      ApiResult.failure(ApiErrorModel(message: 'Connection to server failed'));

  List<int> idsOf(ProfileState state) =>
      (state as ProfileSuccess).posts.map((p) => p.id).toList();

  /// Only the signed-in user's posts are cached, and `_isMe` decides that by
  /// comparing against the cached profile — which `HomeCubit` writes on login.
  Future<void> seedMyProfile() =>
      cache.writeMap(CacheKeys.myProfile, {'id': myId, 'username': 'mo'});

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    root = Directory.systemTemp.createTempSync('riff_profile_cubit_test');
    OfflineCache.resetInstanceForTest();
    cache = OfflineCache.instance..rootOverride = root;
    repo = MockProfileRepo();
    cubit = ProfileCubit(repo, cache: cache);
  });

  tearDown(() async {
    await cubit.close();
    OfflineCache.resetInstanceForTest();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('caches my own posts', () async {
    await seedMyProfile();
    when(repo.getUserPosts(myId))
        .thenAnswer((_) async => ApiResult.success([post(1), post(2)]));

    await cubit.loadUserPosts(myId);

    expect(await cache.readList(CacheKeys.myPosts), hasLength(2));
  });

  test('caches at most the configured number of posts', () async {
    await seedMyProfile();
    when(repo.getUserPosts(myId)).thenAnswer(
        (_) async => ApiResult.success([for (var i = 0; i < 40; i++) post(i)]));

    await cubit.loadUserPosts(myId);

    expect((await cache.readList(CacheKeys.myPosts))!.length,
        CacheKeys.myPostsLimit);
  });

  // Someone else's profile is not ours to keep a copy of.
  test('does not cache another user\'s posts', () async {
    await seedMyProfile();
    when(repo.getUserPosts(otherId))
        .thenAnswer((_) async => ApiResult.success([post(1)]));

    await cubit.loadUserPosts(otherId);

    expect(await cache.readList(CacheKeys.myPosts), isNull);
  });

  // The user's report: profile posts appeared not to be cached at all. They
  // were — the in-memory copy just couldn't be read back, because
  // `Post.toJson()` leaves `author` as an object. See offline_cache_test.md.
  test('cached posts are readable in the same process that cached them',
      () async {
    await seedMyProfile();
    when(repo.getUserPosts(myId))
        .thenAnswer((_) async => ApiResult.success([post(1)]));
    await cubit.loadUserPosts(myId);

    final second = ProfileCubit(repo, cache: cache);
    addTearDown(second.close);
    when(repo.getUserPosts(myId)).thenAnswer((_) async => offline());
    await second.loadUserPosts(myId);

    expect(second.isShowingCached, isTrue);
    expect(idsOf(second.state), [1]);
  });

  test('shows cached posts instead of an error when the request fails',
      () async {
    await seedMyProfile();
    await cache.writeList(
      CacheKeys.myPosts,
      [post(1), post(2)].map((p) => p.toJson()).toList(),
      limit: CacheKeys.myPostsLimit,
    );
    when(repo.getUserPosts(myId)).thenAnswer((_) async => offline());

    await cubit.loadUserPosts(myId);

    expect(cubit.state, isA<ProfileSuccess>());
    expect(idsOf(cubit.state), [1, 2]);
    expect(cubit.isShowingCached, isTrue);
  });

  test('reports a real failure when there is nothing cached', () async {
    when(repo.getUserPosts(myId)).thenAnswer((_) async => offline());

    await cubit.loadUserPosts(myId);

    expect(cubit.state, isA<ProfileFailure>());
  });

  test('live posts replace the cached ones', () async {
    await seedMyProfile();
    await cache.writeList(
      CacheKeys.myPosts,
      [post(1)].map((p) => p.toJson()).toList(),
      limit: CacheKeys.myPostsLimit,
    );
    when(repo.getUserPosts(myId))
        .thenAnswer((_) async => ApiResult.success([post(9)]));

    await cubit.loadUserPosts(myId);

    expect(idsOf(cubit.state), [9]);
    expect(cubit.isShowingCached, isFalse);
  });

  group('deletion', () {
    test('a deleted post disappears from the profile', () async {
      await seedMyProfile();
      when(repo.getUserPosts(myId))
          .thenAnswer((_) async => ApiResult.success([post(1), post(2)]));
      await cubit.loadUserPosts(myId);

      PostEvents.notifyDeleted('2');
      await pumpEventQueue();

      expect(idsOf(cubit.state), [1]);
    });

    test('the cached own-posts copy is pruned as well', () async {
      await seedMyProfile();
      when(repo.getUserPosts(myId))
          .thenAnswer((_) async => ApiResult.success([post(1), post(2)]));
      await cubit.loadUserPosts(myId);

      PostEvents.notifyDeleted('2');
      await pumpEventQueue();

      final cached = await cache.readList(CacheKeys.myPosts);
      expect(cached!.map((p) => p['id']), [1]);
    });

    // The cache only ever holds *my* posts, so a delete while someone else's
    // profile is on screen must not write that profile's posts over it.
    test('viewing another profile does not overwrite my cached posts',
        () async {
      await seedMyProfile();
      await cache.writeList(
        CacheKeys.myPosts,
        [post(1), post(2)].map((p) => p.toJson()).toList(),
        limit: CacheKeys.myPostsLimit,
      );
      when(repo.getUserPosts(otherId))
          .thenAnswer((_) async => ApiResult.success([post(50), post(51)]));
      await cubit.loadUserPosts(otherId);

      PostEvents.notifyDeleted('2');
      await pumpEventQueue();

      final cached = await cache.readList(CacheKeys.myPosts);
      expect(cached!.map((p) => p['id']), [1]);
    });
  });
}
