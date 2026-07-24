# `social_login_test.dart`

Widget tests for `SocialLogin` (`lib/features/auth/login/UI/widgets/social_login.dart`) — the
"Continue with Google" button and its loading/failure states.

## What's mocked

- **`GoogleAuthService`** — a `FakeGoogleAuthService` defined in this file implements the
  `GoogleAuthService` interface (`lib/features/auth/login/UI/widgets/google_sign_in_helper.dart`)
  and is injected via `SocialLogin(googleAuthService: fake)`. This interface didn't exist before
  this test suite — see "Testability fix" below.
- **`LoginRepo`** — mocked (same generated mock as `login_cubit_test.dart`) so a real `LoginCubit`
  can be provided and `verify(mockLoginRepo.loginWithGoogle(...))` can assert the token actually
  reaches the cubit.

## Scenarios covered

- Renders the idle "Continue with Google" state.
- A successful native sign-in (`FakeGoogleAuthService` returns a token) calls
  `LoginCubit.loginWithGoogle` with that exact token.
- A cancelled/failed native sign-in (`FakeGoogleAuthService` returns `null`) shows a failure
  snackbar and never calls the repo.
- While the fake sign-in is pending (simulated with a `delay`), the button shows its own loading
  spinner + "Signing in..." text.

## Testability fix this test suite depends on

`SocialLogin` used to call the static `GoogleSignInHelper.signInAndGetIdToken()` directly, which
wraps the real `google_sign_in` plugin with no way to substitute a fake — any widget test that
tapped the button would hit a real platform channel and throw `MissingPluginException`. Fixed by
extracting a `GoogleAuthService` interface with a `GoogleSignInAuthService` default implementation,
and giving `SocialLogin` an optional `googleAuthService` constructor parameter (defaults to the
real implementation in production, so no other call site needed to change). See `CLAUDE.md` →
Known Bugs Fixed.

## A known gap (documented, not fixed)

`SocialLogin` tracks its own `_isLoading` bool instead of reflecting `LoginCubit`'s actual
`Loading` state — the spinner shown here only covers the native Google picker step, not the
network call `loginWithGoogle()` triggers afterwards. Left as-is; flagged in case a future change
wants to unify the two loading sources.

## Running

```bash
flutter test test/features/auth/login/UI/widgets/social_login_test.dart
```
