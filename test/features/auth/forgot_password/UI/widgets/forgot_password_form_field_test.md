# `forgot_password_form_field_test.dart`

Widget tests for `ForgotPasswordFormField` — the single email field on the "forgot password"
screen.

## What's mocked

- **`ForgotPasswordRepo`** — mocked (reusing the mock generated for
  `forgot_password_cubit_test.dart`) so a real `ForgotPasswordCubit` can be constructed and
  provided via `BlocProvider<ForgotPasswordCubit>.value`. The widget reads
  `context.read<ForgotPasswordCubit>()` for its controller and `formKey`; the repo behind it is
  never actually invoked by these tests.

## Scenarios covered

- Renders the email field with the correct hint text.
- Rejects an empty value and a malformed email (`AppRegex.isEmailValid`), showing the localized
  error.
- Accepts a valid email and clears the error.

## Running

```bash
flutter test test/features/auth/forgot_password/UI/widgets/forgot_password_form_field_test.dart
```
