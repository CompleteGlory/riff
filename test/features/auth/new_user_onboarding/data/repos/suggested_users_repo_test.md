# `suggested_users_repo_test.dart`

Unit tests for `SuggestedUsersRepo` — fetches suggested accounts to follow and matches contacts,
shown during new-user onboarding. There's no cubit for this feature (the screen calls the repo
directly from a `StatefulWidget`'s own local state — see `CLAUDE.md` → Testing for why that screen
itself isn't covered here), so the repo is the only unit worth isolating.

## What's mocked

- **`Dio`** — mocked with `@GenerateMocks([Dio])`. Like `PhoneVerifyRepo`, this repo calls `Dio`
  directly rather than going through `ApiService`.

## Scenarios covered

- `getSuggested`: parses a bare JSON list response, a `{ "data": [...] }`-wrapped response, and
  falls back to an empty list for any other body shape (defensive parsing — the repo doesn't know
  in advance which shape the backend will return); failure when the request throws.
- `findContacts`: posts the given phone numbers and parses the matched users; failure when the
  request throws.

## Running

```bash
flutter test test/features/auth/new_user_onboarding/data/repos/suggested_users_repo_test.dart
```
