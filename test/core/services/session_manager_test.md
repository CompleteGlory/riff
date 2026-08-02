# `session_manager_test.dart`

## What it covers

`SessionManager` — token lifetime, refresh, and sign-out. Three areas:

1. **Expiry parsing** (`expiryOf`, `isExpired`) — reads the `exp` claim out of
   the access JWT, applies a 30-second leeway, and treats an unparseable token
   as *not* expired so an unfamiliar token shape can't cause a refresh loop.
2. **`refreshAccessToken`** — single-flight behaviour, token storage, the
   `onAccessTokenRefreshed` broadcast, and the rejected/transient distinction.
3. **`endSession`** — clears credentials, runs the teardown hooks, leaves
   unrelated preferences (theme, locale) alone.

## What's mocked

- `SessionManager.refreshTransport` is swapped for a callback, so no test
  touches the network. `RefreshOutcome.success/rejected/transientFailure` model
  the three server responses that matter.
- `SharedPreferences.setMockInitialValues({})` in `setUp` — required, since
  every path reads storage.
- `NavigationService.readyTimeout` is shortened in `setUp`. These are pure unit
  tests with no `MaterialApp`, so the login redirect fired by `endSession` finds
  no navigator and would otherwise poll for the full production timeout.

## Regressions locked in

- **The refresh stampede — the "I got signed out after writing a comment"
  report.** `/api/auth/refresh` runs the same use case as log-in: it *rotates*
  the refresh token and stores only a hash of the newest one. The old
  interceptor refreshed once per failed request, so a burst of 401s (posting a
  comment while the feed, chat list and 30-second notification poll were all in
  flight, against a 15-minute access token) fired several refreshes with the
  same token. The first rotated it; every other came back 401 and was treated as
  "your session is over" — and a loser could write an already-invalidated
  refresh token back to storage, poisoning the session until the user logged in
  again by hand. `concurrent callers share a single refresh round-trip` is the
  guard.
- **Transient failures are not sign-outs.** A dropped connection or a 5xx during
  refresh keeps the session; only an actual 401/403 clears it.
- **Expired-token socket handshakes.** `validAccessToken` refreshes before
  handing a token out, because the chat/notification gateways verify it during
  the handshake and hang up when it fails — with no retry afterwards.

## Refresh resilience (added with the offline work)

All of this exists for one report: *"I get signed out for no reason."*

- a transient failure is retried on a backoff instead of leaving the caller with
  a dead token;
- a single rejection is **not** enough — `/auth/refresh` rotates the token, so a
  401 can equally mean this caller lost a race;
- a rejection that arrives while `ConnectivityService` says the device is
  offline is not believed at all, and doesn't even cost a retry;
- a rejection for a refresh token that storage has since rotated is retried with
  the newer one — this is the exact shape of the original bug;
- two *confirmed* rejections do still end the session.

### Gotchas for this group

- `session.sleep` is overridden to a no-op in `setUp`. Without it every failure
  case sits through the real 1s/3s/6s backoff, adding ten seconds per test.
- `ConnectivityService.resetInstanceForTest()` in both `setUp` and `tearDown`:
  it is a singleton, and an offline verdict left behind by one test changes the
  outcome of the next one.
