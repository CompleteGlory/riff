# `delete_account_screen_test.dart`

Covers `DeleteAccountScreen` — the in-app account deletion App Store guideline
5.1.1(v) requires.

## What it covers

**The warning comes first.** The screen names everything that goes — profile,
content, messages, social graph — before it asks for a credential. A reviewer
looks for this, and so does anyone about to delete their account by accident.

**Two confirmation modes, driven by `provider`.** A password account re-enters
its password; an account created through Google has none, so it types its own
username back. The tests assert each mode shows only its own field and sends
only its own credential.

**Nothing deletes without two deliberate steps.** Failing validation shows the
error and never opens the dialog; opening the dialog and cancelling sends
nothing. Only tapping the destructive action in the dialog reaches the repo.

## Mocks

`DeleteAccountRepo` via `@GenerateMocks`. The real `DeleteAccountCubit` is used
— the point is the wiring between form, dialog and cubit.

## Gotchas

- `find.text(s.deleteAccountCancel).last` in the cancel test: the label appears
  both in the dialog and on the screen's own cancel button, and the dialog's is
  the one on top.
- The success path calls `SessionManager.endSession()`, which clears
  SharedPreferences — harmless here (the test binding provides an in-memory
  store) and visible in the test output as `userToken has been removed`, which
  is a useful sign the sign-out actually fires.
