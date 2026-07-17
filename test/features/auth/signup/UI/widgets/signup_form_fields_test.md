# `signup_form_fields_test.dart`

Widget tests for `SignUpFormFields` — full name, username, email, password (with a live strength
meter), and confirm-password.

## What's mocked

- **`SignupRepo`** and **`LoginRepo`** — both mocked (reusing the mocks generated for
  `signup_cubit_test.dart`) purely to construct a real `SignupCubit` for
  `context.read<SignupCubit>()`. Neither is ever actually invoked by these tests.

## Scenarios covered

- Renders all five fields.
- Submitting empty shows every field's required/format error at once (full name, username, email,
  password, confirm-password).
- Username rejects disallowed characters (must match `^[a-zA-Z0-9_.]+$`).
- Password below the strength threshold (`_PasswordStrength.isValid` — needs length ≥ 8, upper,
  lower, number, and special character all present) is rejected with the length/strength message.
- Confirm-password must match the password.
- All fields filled correctly validates successfully.

## A layout pitfall this test suite caught

Pumping `SignUpFormFields` directly inside a bare `Scaffold(body: ...)` (as most of this repo's
other form-field widget tests do) overflows the default 800×600 test viewport — the real form has
five fields plus a password-strength bar and a requirements checklist, and in production it's only
usable because `SignupScreen` wraps it in a `SingleChildScrollView`. This test's `pumpForm()`
helper wraps the widget the same way; without that wrapper, every test in this file fails with a
`RenderFlex overflowed` error before ever reaching its actual assertion.

## Running

```bash
flutter test test/features/auth/signup/UI/widgets/signup_form_fields_test.dart
```
