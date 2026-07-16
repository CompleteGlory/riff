# `login_repo_test.dart`

Unit tests for `LoginRepo` (`lib/features/auth/login/data/repos/login_repo.dart`) — the
repository layer that wraps the raw API call and turns it into app-usable data: cookie/token
extraction, `SharedPreferences` persistence, and `User` parsing.

## What's mocked

- **`ApiService`** — the retrofit-generated HTTP client. Mocked with `mockito`'s
  `@GenerateMocks([ApiService])`, following
  [the Flutter cookbook mocking guide](https://docs.flutter.dev/cookbook/testing/unit/mocking).
  `ApiService` is already an `abstract class`, so it's directly mockable with no extra seam
  needed. The generated mock lives in `login_repo_test.mocks.dart` (run
  `dart run build_runner build` to regenerate after changing `ApiService`).
- **`SharedPreferences`** — real plugin, but backed by `SharedPreferences.setMockInitialValues({})`
  in `setUp()`, which is the plugin's own in-memory test double. `LoginRepo` calls the static
  `SharedPrefHelper` directly (no DI seam), so this is the only way to observe what got persisted.
- **Dio responses** — built by hand as `HttpResponse<dynamic>(data, Response(...))` so each test
  controls the exact cookies/body the "server" returns, without a real network call.

## Scenarios covered

- `LoginRepo.login`
  - Success path: extracts `AccessToken`/`RefreshToken` from `set-cookie` headers, persists them
    and the user id via `SharedPrefHelper`, and returns `ApiResult.success`.
  - Fallback parsing: when the response body has no `user` object, decodes the JWT payload
    (`sub`, `email`) out of the access token instead.
  - Failure path: a thrown `DioException` (connection error, or a 401 `badResponse` with a server
    message) maps to `ApiResult.failure` with the right `ApiErrorModel`.
  - No-cookie response still succeeds without persisting a token (doesn't crash).
- `LoginRepo.loginWithGoogle`
  - Propagates the backend's `isNewUser` flag (true/false) onto `LoginResponse`.
  - Failure path when the Google endpoint throws.

## Bug this test suite caught

The debug logs in `LoginRepo` did `accessToken.substring(0, 20)` with no length check — any
token shorter than 20 characters threw a `RangeError` that the surrounding `try/catch` silently
turned into a **failure result**, even though login had actually succeeded. Covered here by using
short fixture tokens (e.g. `'access-123'`, `'gtoken'`); fixed in `login_repo.dart` via a `_truncate`
helper. See `CLAUDE.md` → Known Bugs Fixed for the summary entry.

## Running

```bash
flutter test test/features/auth/login/data/repos/login_repo_test.dart
```
