# `forgot_password_bloc_listener_test.dart`

Widget tests for `ForgotPasswordBlocListener` — reacts to the "request OTP" step's states
(loading/success/failure) with a dialog and navigation to the enter-code screen.

## What's mocked

- **`ForgotPasswordRepo`** — mocked; a real `ForgotPasswordCubit` is driven through its actual
  `emitForgotPasswordStates()` method rather than faking states directly.
- A stub `/enterCode` route stands in for the real `EnterCodeScreen`.

## Scenarios covered

- Shows a loading dialog while the cubit is `Loading`.
- On success: dismisses the dialog and navigates to `/enterCode`.
- On failure: shows an error dialog with the API's message; navigation does not happen.

## Timing note

Same as `login_bloc_listener_test.md` — the listener defers its dialog/navigation work via
`WidgetsBinding.instance.addPostFrameCallback`, so driving the loading-dialog assertion needs three
separate `tester.pump()` calls (deliver the state → flush the post-frame callback → build/paint
the pushed dialog route), not a single `pump()`/`pump(duration)`.

## Running

```bash
flutter test test/features/auth/forgot_password/UI/widgets/forgot_password_bloc_listener_test.dart
```
