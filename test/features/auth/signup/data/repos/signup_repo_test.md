# `signup_repo_test.dart`

Unit tests for `SignupRepo` (`lib/features/auth/signup/data/repos/signup_repo.dart`) — a thin
wrapper around `ApiService.signUp`, the simplest repo in the auth features.

## What's mocked

- **`ApiService`** — mocked with `@GenerateMocks([ApiService])` (own generated mock file,
  `signup_repo_test.mocks.dart` — kept separate from `login_repo_test.mocks.dart` since mockito
  generates one mock file per annotated test file).

## Scenarios covered

- Success: captures the exact `SignupRequestBody` sent (email, username, instruments, genres).
- Failure: a 409 conflict maps to `ApiErrorModel` with the server's status code and message; a
  connection error also maps to a generic failure.

## Running

```bash
flutter test test/features/auth/signup/data/repos/signup_repo_test.dart
```
