# `forgot_password_cubit_test.dart`

Unit tests for `ForgotPasswordCubit` — verifies the state transitions for all three steps
(`emitForgotPasswordStates`, `emitVerifyOtpState`, `emitResetPasswordState`) against a mocked
`ForgotPasswordRepo`, using `bloc_test`.

## What's mocked

- **`ForgotPasswordRepo`** — mocked with `@GenerateMocks([ForgotPasswordRepo])` (generated into
  `forgot_password_cubit_test.mocks.dart`).
- **`SharedPreferences`** — backed by `SharedPreferences.setMockInitialValues({})`, needed for the
  reset-token-recovery test (see below).

## Scenarios covered

- `emitForgotPasswordStates`: success (captures the email sent to the repo) and failure.
- `emitVerifyOtpState`: success (captures email + otp) and failure.
- `emitResetPasswordState`:
  - Uses the token captured in memory from an earlier `emitVerifyOtpState()` call in the same
    test (the cubit stores it in a private field — there's no setter, so the only way to get a
    token into it from a test is to actually drive that call first).
  - Recovers the token from `SharedPreferences` when nothing is held in memory (this is the
    "resume after app restart" path — `SharedPreferences.setMockInitialValues` is seeded with a
    stored token for this one).
  - Failure path.

## Testability fix this test suite depends on

`ForgotPasswordCubit.emitForgotPasswordStates/emitVerifyOtpState/emitResetPasswordState` were all
declared as `void ... async` instead of `Future<void> ... async` — a fire-and-forget signature
that can't be `await`ed. Widening them to `Future<void>` is a safe, backward-compatible change (no
call site awaited them before, and none needed to change), and it's what lets this test suite (and
the bloc-listener widget tests) sequence `await cubit.emitX()` before asserting on the resulting
state. See `CLAUDE.md` → Known Bugs Fixed.

## Running

```bash
flutter test test/features/auth/forgot_password/logic/cubit/forgot_password_cubit_test.dart
```
