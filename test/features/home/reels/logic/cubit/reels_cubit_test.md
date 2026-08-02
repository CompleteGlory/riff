# `reels_cubit_test.dart`

## What it covers

`ReelsCubit`'s offline behaviour.

- the first page is cached after a successful load, capped at
  `CacheKeys.reelsLimit`;
- **cached reels are readable in the process that cached them** — the reported
  bug (see below);
- a failed request falls back to the cache instead of `ReelsFailure`;
- with nothing cached, a failure is still reported honestly;
- a successful first page *replaces* the cached reels rather than stacking on
  them, so a reel taken down since disappears.

## What's mocked

`ReelsRepo` — mockito mock. `OfflineCache` is real, pointed at a temp directory
via `rootOverride`.

## Gotchas

- `ReelsScreen` creates the cubit with `..loadReels()` — **no** `refresh: true`.
  That matters: the cache is only consulted on the non-refresh page-1 path, so
  a screen that opened with `refresh: true` would silently never use it.
- The fixture uses a post with a nested `author`, not a bare one. A bare `Post`
  serialises to plain JSON and would pass even with the bug below present.
- `OfflineCache.resetInstanceForTest()` in `setUp` — process-wide singleton.

## Regression locked in

Reels looked like they were never cached. They were, on disk — but the
in-memory mirror held `Post.toJson()`'s output verbatim, and that leaves
`author`, `likes` and `comments` as *objects* rather than maps
(json_serializable's default `explicit_to_json: false`). Every read served from
memory threw inside `Post.fromJson` and was swallowed as "nothing cached". Fixed
in `OfflineCache._write` — see
[offline_cache_test.md](../../../../../core/cache/offline_cache_test.md).
