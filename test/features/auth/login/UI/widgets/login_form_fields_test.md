# `login_form_fields_test.dart`

Widget tests for `LoginFormFields` (`lib/features/auth/login/UI/widgets/login_form_fields.dart`)
— the email/username + password `Form` used on the login screen.

## What's mocked

- **`LoginRepo`** — mocked (reusing the mock class generated for `login_cubit_test.dart`, imported
  from `../../logic/cubit/login_cubit_test.mocks.dart`) so a real `LoginCubit` can be constructed
  and provided via `BlocProvider<LoginCubit>.value`. `LoginFormFields` reads
  `context.read<LoginCubit>()` directly for its `TextEditingController`s and `GlobalKey<FormState>`,
  so it needs a real cubit instance in the tree — the repo behind it is irrelevant to these tests
  and is never actually invoked.
- Uses the shared `pumpApp` helper (`test/helpers/pump_app.dart`) to get `S.of(context)`
  localization and `flutter_screenutil` (`.w`/`.h`/`.r`) working, matching how `RiffMaterialApp`
  wraps the real app.

## Scenarios covered

- Renders the email and password labels/fields with the correct localized hint text.
- Password field is obscured by default; tapping the visibility icon reveals it (checked on the
  underlying `TextField`, since `TextFormField` doesn't expose `obscureText` as a public field —
  it's forwarded straight into the `TextField` it builds internally).
- Submitting the form empty surfaces both "required" validation messages.
- Entering valid text clears the validation errors and updates the cubit's controllers.

## Running

```bash
flutter test test/features/auth/login/UI/widgets/login_form_fields_test.dart
```
