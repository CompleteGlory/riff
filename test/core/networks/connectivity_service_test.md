# `connectivity_service_test.dart`

## What it covers

`ConnectivityService` — the app's answer to "are we actually online?", derived
from real request outcomes rather than a plugin.

- **Classifying failures** — a server response (401, 500) is never an offline
  signal; connection/timeout failures are; `DioExceptionType.unknown` is only
  offline when it wraps a `SocketException`; a cancelled request is neither.
- **Status transitions** — starts online, flips on a transport failure, flips
  back on any response, emits only transitions (never repeats), and the
  `ValueNotifier` mirror stays in step.
- **`checkNow`** — a failing probe reports offline, a succeeding one restores
  online, and concurrent callers share a single probe.

## What's mocked

The reachability probe, via the injectable `probe` field. `DioException`s are
constructed directly — no HTTP, no `path_provider`, no plugins, so this runs as
a plain `test` file with no binding.

## Gotchas

- `resetInstanceForTest()` in both `setUp` **and** `tearDown`: the service is a
  singleton with a live backoff `Timer` while offline, and leaving one pending
  fails the next test's binding.
- The status stream is a broadcast `StreamController`, so an assertion on what
  was emitted needs one microtask (`await Future<void>.delayed(Duration.zero)`)
  after the last report.

## Regressions locked in

The classification is the load-bearing part. Treating a 500 as "offline" would
put a "you're offline, showing saved content" banner over a perfectly good
connection, and treating a socket error as a server error would leave the user
staring at a generic failure with a retry button that cannot work.
