# `profile_cubit_test.dart`

## What it covers

`ProfileCubit`'s offline behaviour, including who is allowed to be cached.

- own posts are cached, capped at `CacheKeys.myPostsLimit`;
- **another user's posts are never cached** — the profile bucket belongs to the
  signed-in user;
- cached posts are readable in the process that cached them (the reported bug);
- a failed request falls back to the cache rather than `ProfileFailure`;
- with nothing cached, a failure is still reported;
- live posts replace the cached ones.

## What's mocked

`ProfileRepo` — mockito mock. `OfflineCache` is real, via `rootOverride`.

## Gotchas

- **`seedMyProfile()` is required for any test that expects caching.** "Is this
  me?" is answered by comparing the requested user id against the cached
  `myProfile` map, which in production `HomeCubit` writes on login. Without the
  seed, every profile looks like someone else's and nothing is cached — which is
  correct behaviour, but makes an unseeded test look like a caching bug.
- The fixture uses a post with a nested `author` — see the regression below.
- `OfflineCache.resetInstanceForTest()` in `setUp`.

## Regressions locked in

- **Same in-memory mirror bug as reels** — see
  [offline_cache_test.md](../../../../../core/cache/offline_cache_test.md).
- **The "is this me?" lookup used to happen inside the success callback**, which
  is synchronous, so `_cachePosts` could only start it a microtask later and the
  cache write raced anything reading straight afterwards. It is now resolved
  once at the top of `loadUserPosts`, before the request goes out.
