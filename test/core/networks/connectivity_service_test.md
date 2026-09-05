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

## The banner appeared at launch on a good connection (2026-09-05)

Reported as "I get offline in the app when it starts and it's not offline".
Two causes, both of which treated weak evidence as proof.

**One failed request settled it.** `reportDioError` called `_setOnline(false)`
the moment any transport-level failure arrived. But several things look
identical to a dead network from inside Dio: a cold Railway container taking
too long to answer its first request surfaces as `receiveTimeout`; and
`DioExceptionType.unknown` with no response catches *any* non-network
exception thrown on the way. At cold start the app fires profile, feed,
notifications and chat requests at once, so it only took one of them.

**The probe answered a different question.** `_defaultProbe` was an
`InternetAddress.lookup`. A resolved name does not mean the server is
reachable, and — the part that bit — a failed lookup does not mean the device
is offline. DNS is routinely unavailable for a moment on a device that has just
woken, behind a VPN, or on a network still coming up. `HomeLayout` runs
`checkNow()` on `AppLifecycleState.resumed`, which also fires at launch.

Now: a transport failure is a **suspicion** that triggers a probe, and the probe
decides. The probe is a real HTTP request to the API host where **any** status
counts as reachable, including 401 and 404 — the question is whether packets
get there and back, not whether the server liked the request. It uses a bare
`HttpClient`, because routing it through the app's Dio would report its own
outcome back into this service and probe recursively.

This is the same lesson `SessionManager` already learned: one rejection is not
proof.

### The race this introduced, and the guard for it

Making the offline decision asynchronous broke an existing test, correctly. A
probe started by a failed request can land *after* the next request has already
succeeded, and applying its stale answer drags a working app offline. Every
definitive report — a real response — now bumps an epoch, and a probe that
started before the bump discards its result. The same trick `NotificationsCubit`
uses against a poll that would overwrite a local change.

`pumpProbe()` exists because the status now settles a microtask after a failure
rather than synchronously with it; a test that asserts immediately after
`reportDioError` is asserting on the suspicion, not the verdict.
