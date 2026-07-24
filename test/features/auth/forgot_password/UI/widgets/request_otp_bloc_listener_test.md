# `request_otp_bloc_listener_test.dart`

Widget tests for `VerifyOTPBlocListener` (in `request_otp_bloc_listener.dart` — the file name
doesn't match the class name in the source; the test file name matches the source file, not the
class) — reacts to the "verify OTP" step's states with a dialog and navigation to the reset
password screen.

## What's mocked

- **`ForgotPasswordRepo`** — mocked; a real `ForgotPasswordCubit` is driven through
  `emitVerifyOtpState()`.
- A stub `/resetPassword` route stands in for the real `ResetPasswordScreen`.

## Scenarios covered

- Shows a loading dialog while the cubit is in `otpVerificationLoading`.
- On success: dismisses the dialog and navigates to `/resetPassword`.
- On an invalid code: shows an error dialog with the API's message.

## Running

```bash
flutter test test/features/auth/forgot_password/UI/widgets/request_otp_bloc_listener_test.dart
```
