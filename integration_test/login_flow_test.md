# `login_flow_test.dart`

End-to-end integration test for the whole login feature, driven through the real widget tree
(`LoginScreen` → `LoginFormFields` / `SocialLogin` / `LoginBlocListener` → `LoginCubit`) using the
Flutter [`integration_test`](https://docs.flutter.dev/testing/integration-tests) package. This is
the outermost layer of the test pyramid for this feature — the other files under
`test/features/auth/login/` cover the same behavior in isolation at the unit/widget level; this
file proves it all still works wired together, closer to how a real device would run it.

## What's mocked

- **`LoginRepo`** — the *only* thing mocked. Reuses the `MockLoginRepo` already generated for
  `test/features/auth/login/logic/cubit/login_cubit_test.dart` (imported via a relative path —
  see "Why no separate mock" below) so the test never hits the real Riff API, per
  [the Flutter cookbook mocking guide](https://docs.flutter.dev/cookbook/testing/unit/mocking).
- Everything else — `LoginCubit`, `LoginScreen` and all its child widgets, form validation,
  navigation — is the real production code.
- Stub `/home`, `/signup`, `/forgotPassword` routes stand in for the real destination screens,
  the same simplification `login_screen_test.dart` makes, so the test doesn't need to boot the
  rest of the app's DI graph just to prove login navigates correctly.

## Why no separate mock file

`@GenerateMocks` needs `build_runner` to have scanned the file, and by default Flutter's
`build_runner` config only processes `lib/` and `test/`, not `integration_test/`. Rather than add
build_runner configuration just for one mock, this file imports the mock class already generated
for the cubit unit tests (`../test/features/auth/login/logic/cubit/login_cubit_test.mocks.dart`).
If that file ever moves, update the import path here too.

## Scenarios covered

- A user with valid credentials can log in: fills the form, taps "Login", sees the loading dialog
  appear, and lands on the stub Home route — with the repo receiving exactly the typed
  email/password.
- A user cannot submit the form with empty fields — both validation messages show and the repo is
  never called.
- A user with rejected credentials sees the error dialog with the server's message and stays on
  `LoginScreen`; dismissing the dialog closes it.
- A user can navigate to the forgot-password and signup screens from the login screen.

## Running

Requires a connected device or simulator (this is a real `integration_test`, not a hosted widget
test):

```bash
flutter test integration_test/login_flow_test.dart -d <device-id>
# or: flutter drive --driver=test_driver/integration_test.dart --target=integration_test/login_flow_test.dart
```
