# `reset_password_bloc_listener_test.dart`

Widget tests for `ResetPasswordBlocListener` — reacts to the final "reset password" step's states
with a loading dialog, a success dialog (with a "proceed to login" action), or an error dialog.

## What's mocked

- **`ForgotPasswordRepo`** — mocked; a real `ForgotPasswordCubit` is driven through
  `emitResetPasswordState()`.
- **`SharedPreferences`** — backed by `SharedPreferences.setMockInitialValues({})`. This one is
  load-bearing, not boilerplate — see the pitfall below.
- A stub `/login` route stands in for the real `LoginScreen`.

## Scenarios covered

- Shows a loading dialog while resetting.
- On success: shows the success dialog (checkmark image + message), and tapping "proceed to
  login" navigates to `/login`.
- On failure: shows an error dialog with the API's message.

## Pitfall this test suite caught: an indefinite hang, not a failure

None of these tests ever call `emitForgotPasswordStates()`/`emitVerifyOtpState()` first, so the
cubit's in-memory `_resetToken` is always empty when `emitResetPasswordState()` runs. That makes
the cubit fall into its SharedPreferences-recovery branch:

```dart
if (_resetToken.isEmpty) {
  final stored = await SharedPrefHelper.getString(SharedPrefKeys.userToken);
  ...
}
```

Without `SharedPreferences.setMockInitialValues(...)` called first, `SharedPreferences.getInstance()`
hits a real platform channel with no test handler registered — and unlike a widget-tree assertion
timeout (which `pumpAndSettle()` bounds and reports as "pumpAndSettle timed out"), this is a bare
`await` in production code with no bound on it at all. The test doesn't fail — it hangs forever,
eventually taking down the whole `flutter test` process (observed as a `SIGTERM`'d subprocess
after several minutes, not a clean test failure). If a forgot-password test ever seems to hang
rather than fail outright, check for a missing `SharedPreferences.setMockInitialValues` first.

## Running

```bash
flutter test test/features/auth/forgot_password/UI/widgets/reset_password_bloc_listener_test.dart
```
