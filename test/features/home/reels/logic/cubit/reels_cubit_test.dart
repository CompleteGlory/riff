import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/cache/cache_keys.dart';
import 'package:riff/core/cache/offline_cache.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/models/author.dart';
import 'package:riff/features/home/feed/data/models/pagination.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/data/models/posts_response.dart';
import 'package:riff/features/home/reels/data/repos/reels_repo.dart';
import 'package:riff/features/home/reels/logic/cubit/reels_cubit.dart';
import 'package:riff/features/home/reels/logic/cubit/reels_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reels_cubit_test.mocks.dart';

/// See reels_cubit_test.md for what this covers and why.
@GenerateMocks([ReelsRepo])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReelsRepo repo;
  late Directory root;
  late OfflineCache cache;
  late ReelsCubit cubit;

  /// Shaped like the API sends it — the nested `author` is the part that used
  /// to make the cached copy unreadable.
  Post reel(int id) => Post(
        id: id,
        author: Author(id: 'a1', fullName: 'Mo', username: 'mo'),
        content: 'reel $id',
        createdAt: '2026-08-01T10:00:00Z',
        updatedAt: '2026-08-01T10:00:00Z',
        isLiked: false,
        likesCount: '0',
        media: const ['https://cdn/clip.mp4'],
      );

  ApiResult<PostsResponse> ok(List<Post> reels, {int totalPages = 2}) =>
      ApiResult.success(PostsResponse(
        data: reels,
        pagination:
            Pagination(page: 1, limit: 10, total: 20, totalPages: totalPages),
      ));

  ApiResult<PostsResponse> offline() =>
      ApiResult.failure(ApiErrorModel(message: 'Connection to server failed'));

  List<int> idsOf(ReelsState state) =>
      (state as ReelsSuccess).reels.map((r) => r.id).toList();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    root = Directory.systemTemp.createTempSync('riff_reels_cubit_test');
    OfflineCache.resetInstanceForTest();
    cache = OfflineCache.instance..rootOverride = root;
    repo = MockReelsRepo();
    cubit = ReelsCubit(repo, cache: cache);
  });

  tearDown(() async {
    await cubit.close();
    OfflineCache.resetInstanceForTest();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('caches the first page after a successful load', () async {
    when(repo.getReels(any, any)).thenAnswer((_) async => ok([reel(1)]));

    await cubit.loadReels();

    expect(await cache.readList(CacheKeys.reels), hasLength(1));
  });

  test('caches at most the configured number of reels', () async {
    when(repo.getReels(any, any))
        .thenAnswer((_) async => ok([for (var i = 0; i < 30; i++) reel(i)]));

    await cubit.loadReels();

    expect((await cache.readList(CacheKeys.reels))!.length,
        CacheKeys.reelsLimit);
  });

  // The user's report: reels appeared not to be cached at all. They were — the
  // in-memory copy just couldn't be read back, because `Post.toJson()` leaves
  // `author` as an object. See offline_cache_test.md.
  test('cached reels are readable in the same process that cached them',
      () async {
    when(repo.getReels(any, any)).thenAnswer((_) async => ok([reel(1)]));
    await cubit.loadReels();

    final second = ReelsCubit(repo, cache: cache);
    addTearDown(second.close);
    when(repo.getReels(any, any)).thenAnswer((_) async => offline());
    await second.loadReels();

    expect(second.isShowingCached, isTrue);
    expect(idsOf(second.state), [1]);
  });

  test('shows cached reels instead of an error when the request fails',
      () async {
    await cache.writeList(
      CacheKeys.reels,
      [reel(1), reel(2)].map((r) => r.toJson()).toList(),
      limit: CacheKeys.reelsLimit,
    );
    when(repo.getReels(any, any)).thenAnswer((_) async => offline());

    await cubit.loadReels();

    expect(cubit.state, isA<ReelsSuccess>());
    expect(idsOf(cubit.state), [1, 2]);
    expect(cubit.isShowingCached, isTrue);
  });

  test('reports a real failure when there is nothing cached', () async {
    when(repo.getReels(any, any)).thenAnswer((_) async => offline());

    await cubit.loadReels();

    expect(cubit.state, isA<ReelsFailure>());
  });

  test('live reels replace the cached ones rather than stacking on them',
      () async {
    await cache.writeList(
      CacheKeys.reels,
      [reel(1)].map((r) => r.toJson()).toList(),
      limit: CacheKeys.reelsLimit,
    );
    when(repo.getReels(any, any)).thenAnswer((_) async => ok([reel(9)]));

    await cubit.loadReels();

    expect(idsOf(cubit.state), [9]);
    expect(cubit.isShowingCached, isFalse);
  });
}
