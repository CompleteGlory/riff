import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/cache/cache_keys.dart';
import 'package:riff/core/cache/offline_cache.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart' as api;
import 'package:riff/features/home/feed/data/models/author.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';
import 'package:riff/features/home/feed/data/models/pagination.dart';
import 'package:riff/features/home/feed/data/models/post_like.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/data/models/posts_response.dart';
import 'package:riff/features/home/feed/data/repos/feed_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'feed_cubit_test.mocks.dart';

/// See feed_cubit_test.md for what this covers and why.
@GenerateMocks([FeedRepo])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFeedRepo repo;
  late Directory root;
  late OfflineCache cache;
  late FeedCubit cubit;

  Post post(int id) => Post(
        id: id,
        author: null,
        content: 'post $id',
        createdAt: '2026-08-01T10:00:00Z',
        updatedAt: '2026-08-01T10:00:00Z',
        isLiked: false,
        likesCount: '0',
      );

  /// A post shaped the way the API actually sends one — nested author, likes
  /// and comments — rather than the bare object the other cases use. The nested
  /// objects are the whole point: `Post.toJson()` leaves them as objects.
  Post nestedPost(int id) => Post(
        id: id,
        author: Author(id: 'a1', fullName: 'Mo', username: 'mo'),
        content: 'post $id',
        createdAt: '2026-08-01T10:00:00Z',
        updatedAt: '2026-08-01T10:00:00Z',
        isLiked: false,
        likesCount: '2',
        likes: [
          PostLike(id: 1, author: Author(id: 'u1', fullName: 'U', username: 'u'))
        ],
        comments: [
          Comment(id: 1, content: 'nice', createdAt: '2026-08-01T10:00:00Z'),
        ],
      );

  PostsResponse page(List<Post> posts, {int page = 1, int totalPages = 3}) =>
      PostsResponse(
        data: posts,
        pagination: Pagination(
          page: page,
          limit: 4,
          total: totalPages * 4,
          totalPages: totalPages,
        ),
      );

  // FeedState.success carries its payload as the freezed generic, which erases
  // to dynamic at the call site — cast before reaching into it.
  List<int> idsOf(FeedState state) =>
      ((state as Success).data as PostsResponse)
          .data
          .map((p) => p.id)
          .toList();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    root = Directory.systemTemp.createTempSync('riff_feed_cubit_test');
    OfflineCache.resetInstanceForTest();
    cache = OfflineCache.instance..rootOverride = root;
    repo = MockFeedRepo();
    when(repo.getTrendingPost())
        .thenAnswer((_) async => const api.ApiResult.success(null));
    cubit = FeedCubit(repo, cache: cache);
  });

  tearDown(() async {
    await cubit.close();
    OfflineCache.resetInstanceForTest();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  group('caching', () {
    test('caches the first page after a successful load', () async {
      when(repo.getPosts(any, any))
          .thenAnswer((_) async => api.ApiResult.success(page([post(1), post(2)])));

      await cubit.getPosts();

      expect(await cache.readList(CacheKeys.feedPosts), hasLength(2));
    });

    test('only the first page is cached', () async {
      when(repo.getPosts(1, any))
          .thenAnswer((_) async => api.ApiResult.success(page([post(1)])));
      when(repo.getPosts(2, any)).thenAnswer(
          (_) async => api.ApiResult.success(page([post(2)], page: 2)));

      await cubit.getPosts();
      await cubit.getPosts();

      final cached = await cache.readList(CacheKeys.feedPosts);
      expect(cached!.map((p) => p['id']), [1]);
    });

    test('caches at most the configured number of posts', () async {
      final many = [for (var i = 0; i < 40; i++) post(i)];
      when(repo.getPosts(any, any))
          .thenAnswer((_) async => api.ApiResult.success(page(many)));

      await cubit.getPosts();

      expect((await cache.readList(CacheKeys.feedPosts))!.length,
          CacheKeys.feedPostsLimit);
    });
  });

  // The point of the whole exercise: no connection should mean "here is what
  // you were reading", not a spinner followed by an error page.
  group('offline fallback', () {
    Future<void> seedCache() async {
      await cache.writeList(
        CacheKeys.feedPosts,
        [post(1), post(2)].map((p) => p.toJson()).toList(),
        limit: CacheKeys.feedPostsLimit,
      );
    }

    api.ApiResult<PostsResponse> offlineFailure() => api.ApiResult.failure(
          ApiErrorModel(
            statusCode: kOfflineStatusCode,
            message: 'Connection to server failed',
          ),
        );

    test('shows cached posts instead of an error when the request fails',
        () async {
      await seedCache();
      when(repo.getPosts(any, any)).thenAnswer((_) async => offlineFailure());

      await cubit.getPosts();

      expect(cubit.state, isA<Success>());
      expect(idsOf(cubit.state), [1, 2]);
      expect(cubit.isShowingCached, isTrue);
    });

    // The reported bug: the cached feed appeared once and then vanished. The
    // cache was fine on disk — `json.encode` calls `toJson()` on anything it
    // can't encode — but the in-memory mirror held `Post.toJson()`'s output
    // verbatim, and that leaves `author`/`likes`/`comments` as *objects*. So the
    // very next read in the same process threw inside `Post.fromJson` and was
    // swallowed as "nothing cached".
    test('a cached post with nested objects survives a same-process reload',
        () async {
      when(repo.getPosts(any, any)).thenAnswer(
          (_) async => api.ApiResult.success(page([nestedPost(1)])));
      await cubit.getPosts();

      // A second cubit, same process — the mirror is what it reads.
      final second = FeedCubit(repo, cache: cache);
      addTearDown(second.close);
      when(repo.getPosts(any, any)).thenAnswer((_) async => offlineFailure());
      await second.getPosts();

      expect(second.isShowingCached, isTrue,
          reason: 'the in-memory copy must be readable, not just the disk one');
      expect(idsOf(second.state), [1]);
      expect(((second.state as Success).data as PostsResponse)
          .data.first.author?.username, 'mo');
    });

    test('reports a real failure when there is nothing cached', () async {
      when(repo.getPosts(any, any)).thenAnswer((_) async => offlineFailure());

      await cubit.getPosts();

      expect(cubit.state, isA<Error>());
      expect(cubit.isShowingCached, isFalse);
    });

    test('live posts replace the cached ones rather than stacking on them',
        () async {
      await seedCache();
      when(repo.getPosts(any, any))
          .thenAnswer((_) async => api.ApiResult.success(page([post(9)])));

      await cubit.getPosts();

      expect(idsOf(cubit.state), [9],
          reason: 'a post deleted since the cache was written must not linger');
      expect(cubit.isShowingCached, isFalse);
    });

    // Blanking the list at the start of a refresh, then failing, left the user
    // staring at an empty feed they had been reading a second earlier.
    test('a failed refresh keeps the posts already on screen', () async {
      when(repo.getPosts(any, any))
          .thenAnswer((_) async => api.ApiResult.success(page([post(1)])));
      await cubit.getPosts();

      when(repo.getPosts(any, any)).thenAnswer((_) async => offlineFailure());
      await cubit.getPosts(refresh: true);

      expect(idsOf(cubit.state), [1]);
      // Page 1 failing is not a "couldn't load more" failure, so the footer
      // error must not appear at the bottom of the list.
      expect(cubit.lastError, isNull);
    });
  });
}
