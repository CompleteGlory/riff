# `offline_cache_test.dart`

## What it covers

`OfflineCache`, the JSON-file store behind every "showing saved content"
fallback in the app.

- **Lists** — round-trip, truncation to the bucket's limit, a never-written key
  reading as `null`, and the `saved_at` stamp the UI shows as "saved 5m ago".
- **Maps** — round-trip, and a type mismatch (reading a list as a map) giving
  `null` rather than throwing.
- **Failure handling** — a corrupt file and a file holding something other than
  the envelope both read as "no cache".
- **User scoping** — each user id gets its own partition, `clear()` wipes every
  partition (this is what the sign-out hook calls), and `remove()` drops one
  bucket.

## What's mocked

Nothing. The cache is pointed at a real temp directory via the
`@visibleForTesting` `rootOverride`, so the tests exercise the actual file I/O
rather than a fake of it. `path_provider` is never reached.

## Gotchas

- **The cache mirrors writes in memory**, so a read straight after a write is
  served without touching the disk. Any test that means to assert *what landed
  on disk* has to call `OfflineCache.resetInstanceForTest()` and re-point a
  fresh instance at the same directory first — see the truncation test.
- **It is a process-wide singleton.** Any other test that constructs a cubit
  which caches (feed, reels, chats, chat, profile, search) needs
  `resetInstanceForTest()` in its own `setUp`, or a list cached by an earlier
  test gets restored into a later one that expected an empty start. That is
  exactly what broke `chats_list_cubit_test` when the cache was introduced.
- `SharedPreferences.setMockInitialValues({})` is required: the scope is
  resolved from the stored user id on first use, and without the mock that
  platform call never completes.

## Regressions locked in

Every failure path returns "no cache" rather than propagating. A cache exists to
make a screen better on a bad connection; it must never be the reason a screen
fails on a good one.
