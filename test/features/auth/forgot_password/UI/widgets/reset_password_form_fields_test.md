# `reset_password_form_fields_test.dart`

Widget tests for `ResetPasswordFormFields` — the new-password + confirm-password fields on the
final step of the forgot-password flow.

## What's mocked

- **`ForgotPasswordRepo`** — mocked (same mock as `forgot_password_cubit_test.dart`), only to
  construct a real `ForgotPasswordCubit` for `context.read<ForgotPasswordCubit>()` to find. Never
  actually invoked.

## Scenarios covered

- Renders both password fields.
- Rejects a new password under 8 characters.
- Rejects a confirm-password value that doesn't match the new password.
- Accepts matching, long-enough passwords.

## Running

```bash
flutter test test/features/auth/forgot_password/UI/widgets/reset_password_form_fields_test.dart
```
