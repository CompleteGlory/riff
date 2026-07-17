# `signup_cubit_test.dart`

Unit tests for `SignupCubit` — notable because it depends on **two** repos: `SignupRepo` for the
actual signup call, and `LoginRepo` for the auto-login that follows a successful signup (so the
JWT is already saved before the phone-verify step).

## What's mocked

- **`SignupRepo`** and **`LoginRepo`** — both mocked via `@GenerateMocks([SignupRepo, LoginRepo])`
  in one file. `LoginRepo`'s mock class is shared in spirit with `login_cubit_test.dart`'s, but
  mockito generates a fresh one per annotated file (`signup_cubit_test.mocks.dart`).

## Scenarios covered

- Signup succeeds + auto-login succeeds → emits `[loading, success]`; captures both the
  `SignupRequestBody` (email, instruments, genres) and the `LoginRequestBody` (email, password)
  sent to their respective repos.
- Signup succeeds but auto-login fails → **still** emits `[loading, success]` — this is
  deliberate production behavior (`loginResult.when(success: ..., failure: (_) => emit(success))`,
  commented `// proceed anyway` in the cubit): a failed background login shouldn't block the user
  from continuing to phone verification.
- Signup itself fails → emits `[loading, failure]` with the server's message, and `LoginRepo.login`
  is never called (verified with `verifyNever`).

## A generic-typing gotcha, sidestepped rather than needing a fix

`SignupState<T>`'s `Success<T>` class collides on the name `Success` with `api_result.dart`'s own
`Success<T>` — same issue as `login_cubit_test.dart`. Fixed the same way: `import
'package:riff/core/networks/api_result.dart' hide Success, Failure;`. Unlike login, this suite
doesn't need to inspect `.data` off the success state (signup's response payload is unused —
`SignupCubit` emits `SignupState.success(null)` and nothing downstream reads it), so the matchers
just use bare `isA<Success>()` without pinning down a generic type argument.

## Running

```bash
flutter test test/features/auth/signup/logic/cubit/signup_cubit_test.dart
```
