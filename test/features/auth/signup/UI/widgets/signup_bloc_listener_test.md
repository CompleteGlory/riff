# `signup_bloc_listener_test.dart`

Widget tests for `SignupBlocListener` — reacts to `SignupCubit`'s states with a loading dialog,
navigation to new-user onboarding on success, or an error dialog.

## What's mocked

- **`SignupRepo`** and **`LoginRepo`** — both mocked; a real `SignupCubit` is driven through its
  actual `emitSignupStates()` method.
- A stub `/newUserOnboarding` route stands in for the real onboarding screen.

## Scenarios covered

- Shows a loading dialog while signing up.
- On success: dismisses the dialog and navigates to `/newUserOnboarding`. Phone verification used
  to sit between the two; it was removed (see `CLAUDE.md` → Known Bugs Fixed), so signup must land
  the user directly on onboarding.
- On failure: shows an error dialog with the server's message, and navigates nowhere; dismissing it
  clears the dialog.

## Pitfall this test suite caught: an unstubbed dependent mock hides the real bug

The "loading dialog" test only cared about `SignupRepo.signUp`'s pending state, so it originally
left `LoginRepo.login` unstubbed. But `SignupCubit.emitSignupStates()` always calls
`_loginRepo.login(...)` after a successful signup (see `signup_cubit_test.md`) — an unstubbed
mockito call on a non-nullable `Future<...>` return type throws inside the cubit, which aborts
`emitSignupStates()` **before** it ever emits the `Success`/`Error` state that would replace the
loading dialog. The visible symptom wasn't an assertion failure — it was `pumpAndSettle() timed
out`, because the indeterminate `CircularProgressIndicator` from the loading dialog was still on
screen and no `Error`/`Success` state was ever reached to replace it. Whenever a `pumpAndSettle
timed out` shows up around a loading dialog, check for an unstubbed dependent mock call before
assuming it's a timing issue. Fix: stub `LoginRepo.login` in that test too, even though the test
doesn't assert on its result.

## Running

```bash
flutter test test/features/auth/signup/UI/widgets/signup_bloc_listener_test.dart
```
