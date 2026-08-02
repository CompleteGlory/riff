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
- **JSON normalisation** — an in-memory read is byte-identical to a read after a
  restart, a nested object is mirrored as a *map* rather than as itself, and a
  payload that cannot be encoded is not cached at all (not even in memory).
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

**The in-memory mirror used to store whatever `toJson()` returned**, and that is
not always JSON. With json_serializable's default `explicit_to_json: false`,
`Post.toJson()` emits its nested `author`, `likes` and `comments` as *objects*.
`json.encode` papers over this on the way to disk — its default `toEncodable`
calls `toJson()` on anything it can't encode — so the **disk copy was always
correct** and a read after a restart worked fine. But any read served from the
mirror handed those objects straight back, `Post.fromJson`'s
`json['author'] as Map<String, dynamic>` threw, and the caller's `catch` reported
it as "nothing cached".

The symptom was baffling from the outside: the cached feed appeared once and
then vanished, and reels and profile posts looked like they were never cached at
all — while chat messages, whose models have hand-written `toJson()`s returning
plain maps, worked perfectly. `_write` now encodes first and mirrors the
re-decoded result, so memory and disk cannot disagree, for any model, including
ones added later.
