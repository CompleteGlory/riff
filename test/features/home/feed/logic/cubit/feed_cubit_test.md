# `feed_cubit_test.dart`

## What it covers

`FeedCubit`'s offline behaviour — the cache write on the way in, and the
fallback on the way out.

- **Caching** — the first page is cached after a successful load, later pages
  are not (they would push the newest posts out of a 10-post bucket), and the
  bucket is capped at `CacheKeys.feedPostsLimit`.
- **Offline fallback** — a failed request with a cache shows the cached posts
  and sets `isShowingCached`; a failed request with no cache still reports a
  real failure; a successful first page *replaces* the cached posts rather than
  appending to them; and a failed pull-to-refresh keeps what was already on
  screen.

## What's mocked

`FeedRepo` — mockito mock (`@GenerateMocks`). `OfflineCache` is real, pointed at
a temp directory through `rootOverride`, so the cache round-trip is genuinely
exercised.

## Gotchas

- `OfflineCache.resetInstanceForTest()` in `setUp`, for the reason described in
  [offline_cache_test.md](../../../../../core/cache/offline_cache_test.md): the
  in-memory mirror survives between tests otherwise.
- `getTrendingPost()` has to be stubbed even though nothing here asserts on it —
  `getPosts(refresh: true)` fires it unawaited, and an unstubbed mock throws
  inside the cubit.
- `FeedState.success` carries its payload as the freezed generic, which erases
  to `dynamic` at the call site. Cast to `PostsResponse` before reaching in, or
  the list comes back as `List<dynamic>` and the matcher fails on the type
  rather than the content.

## Regressions locked in

- **A failed refresh used to blank the feed.** `getPosts(refresh: true)` cleared
  the post list up front, so a refresh on a dying connection replaced the posts
  the user was reading with an error page. The list is now cleared only when the
  replacement actually arrives.
- **The page-1 failure no longer sets `lastError`.** It used to render the
  "couldn't load more posts" footer at the bottom of the list, which described
  the wrong thing entirely.
