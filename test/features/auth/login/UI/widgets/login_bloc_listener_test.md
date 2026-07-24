# `login_bloc_listener_test.dart`

Widget tests for `LoginBlocListener`
(`lib/features/auth/login/UI/widgets/login_bloc_listener.dart`) — the invisible widget that turns
`LoginCubit` state changes into dialogs and navigation.

## What's mocked

- **`LoginRepo`** — mocked (same generated mock as `login_cubit_test.dart`). A real `LoginCubit`
  is built on top of it and driven through its real public methods (`emitLoginStates()`,
  `loginWithGoogle()`) rather than faking states directly, so the listener reacts to genuine state
  transitions.
- **`onLoginSuccess`** — a no-op fake (`() async { onLoginSuccessCalled = true; }`) passed to
  `LoginBlocListener`, standing in for the real `PushNotificationService.instance.init()` call.
- Navigation is exercised against a stub `'/home'` route (`Scaffold(body: Text('HOME'))`) rather
  than the real `HomeLayout`, since booting the real home screen would require the entire app's
  DI graph.

## Scenarios covered

- Shows a `CircularProgressIndicator` dialog while the cubit is `Loading`.
- On success: dismisses the loading dialog, navigates to `/home` (clearing the stack), and calls
  `onLoginSuccess`.
- On failure: shows an `AlertDialog` with the API's error message; dismissing it clears the dialog.
- Signup flow (`isSignupFlow: true`) + Google login returning `isNewUser: false`: shows the
  "Gmail already linked" dialog before navigating home.
- Outside the signup flow, the same `isNewUser: false` result skips that dialog entirely.

## Testability fix this test suite depends on

`LoginBlocListener` used to call the `PushNotificationService.instance.init()` singleton directly
on login success — that singleton talks to real Firebase Messaging / local-notification platform
channels, which throw in a widget-test environment (no Firebase app initialized). Fixed by adding
an optional `onLoginSuccess` constructor parameter (defaults to the real singleton call in
production), forwarded from `LoginScreen` as well. See `CLAUDE.md` → Known Bugs Fixed.

## A timing note (BlocListener + post-frame callbacks)

`LoginBlocListener`'s `listener` wraps its UI work in
`WidgetsBinding.instance.addPostFrameCallback`. Driving it from a test therefore needs **three**
separate `tester.pump()` calls after triggering a state change: one to deliver the new state to
the listener (state changes propagate via a broadcast stream, i.e. on a microtask, not
synchronously), one to flush the queued post-frame callback that calls `showDialog`, and one more
to actually build/paint the pushed dialog route. A single `pump()` (or `pump(someDuration)`) is
not enough and will report zero matching widgets even though the dialog is about to appear.

## Running

```bash
flutter test test/features/auth/login/UI/widgets/login_bloc_listener_test.dart
```
