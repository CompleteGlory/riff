# `forgot_password_repo_test.dart`

Unit tests for `ForgotPasswordRepo` (`lib/features/auth/forgot_password/data/repos/forgot_pasword_repo.dart`)
— the repo backing the three-step forgot-password flow (request OTP → verify OTP → reset
password).

## What's mocked

- **`ApiService`** — mocked with `mockito`'s `@GenerateMocks([ApiService])`, same pattern as
  `login_repo_test.dart`. Regenerate via `dart run build_runner build` after changing `ApiService`.
- **`SharedPreferences`** — real plugin backed by `SharedPreferences.setMockInitialValues({})`,
  since `ForgotPasswordRepo` calls the static `SharedPrefHelper` directly whenever a response
  carries a reset token.

## Scenarios covered

- `requestOtp` / `verifyOtp`: both extract a `reset_token` (or camelCase `resetToken`) out of the
  raw response body when present, persist it via `SharedPrefHelper`, and return it; return
  `success(null)` when the body has neither key; return `failure` when the API call throws.
- `resetPassword`: success and failure (API throws) paths.

## Note on `HttpResponse<void>`

`ApiService.requestOtp/verifyOtp/resetPassword` all return `Future<HttpResponse<void>>` per their
retrofit signatures. The repo doesn't read `HttpResponse.data` (which is `void`/discarded) — it
reads the raw Dio `Response.data` via `response.response.data`. The test's `buildVoidResponse()`
helper mirrors exactly what the generated retrofit code does (`HttpResponse(null, dioResponse)`),
with the fake JSON body attached to the inner Dio `Response`.

## Running

```bash
flutter test test/features/auth/forgot_password/data/repos/forgot_password_repo_test.dart
```
