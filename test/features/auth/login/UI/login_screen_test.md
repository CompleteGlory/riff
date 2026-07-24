# `login_screen_test.dart`

Composite widget tests for the full `LoginScreen`
(`lib/features/auth/login/UI/login_screen.dart`) — form fields, submit button, social login, and
the bloc listener all wired together as they are in production, minus the network layer.

## What's mocked

- **`LoginRepo`** — mocked (same generated mock as `login_cubit_test.dart`); a real `LoginCubit`
  built on top of it is provided via `BlocProvider<LoginCubit>.value`.
- **`onLoginSuccess`** — `LoginScreen(onLoginSuccess: () async {})`, forwarded down to its internal
  `LoginBlocListener`, to avoid hitting the real `PushNotificationService` singleton (same reason
  as `login_bloc_listener_test.dart`).
- Stub routes for `/home`, `/signup`, `/forgotPassword` so navigation can be asserted without
  booting the real destination screens.

## Scenarios covered

- Renders the title, login CTA, and "Continue with Google" button; doesn't call the repo just by
  rendering.
- Tapping "Login" with empty fields shows both validation messages and never calls the repo.
- Entering valid credentials and tapping "Login" calls `LoginRepo.login` with a `LoginRequestBody`
  matching exactly what was typed, and navigates to `/home` on success.
- Wrong credentials show the API's error message in a dialog and do **not** navigate away from
  `LoginScreen`.
- The "Join"/signup link and the "reset your password" link navigate to their respective stub
  routes.

## Testability fix this test suite depends on

`LoginScreen` originally hardcoded `const LoginBlocListener()` with no way to override its
post-success side effect, which meant any full-screen test exercising a successful login would
crash on the real `PushNotificationService` singleton (see the note in
`login_bloc_listener_test.md`). `LoginScreen` now accepts an optional `onLoginSuccess` and forwards
it to `LoginBlocListener`, so both the isolated listener test and this full-screen test can supply
a no-op. See `CLAUDE.md` → Known Bugs Fixed.

## Running

```bash
flutter test test/features/auth/login/UI/login_screen_test.dart
```
