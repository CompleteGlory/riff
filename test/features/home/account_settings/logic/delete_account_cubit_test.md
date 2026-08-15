# `delete_account_cubit_test.dart`

Covers `DeleteAccountCubit` — the state transitions behind permanent account
deletion.

## What it covers

- loading → success on an accepted deletion;
- a **401 is flagged `wrongCredential`**, everything else is a general failure.
  The screen shows the first against the password field and the second as a
  "couldn't delete your account" snackbar, so getting this wrong would tell
  someone with a typo that the server was broken;
- the typed username is passed straight through for OAuth accounts;
- a retry clears the previous error before the request goes out, so a stale
  "incorrect password" doesn't sit under a field the user has just corrected.

## Mocks

`DeleteAccountRepo` via `@GenerateMocks`, stubbed with `anyNamed` for both
optional arguments.

## Note

The cubit deliberately does **not** sign the user out — `DeleteAccountScreen`
does that on `success`, where there is a `BuildContext` to show the confirmation
and navigate with. Keeping `SessionManager` out of the cubit is also what lets
these tests run without touching SharedPreferences.
