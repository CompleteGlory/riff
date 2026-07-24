# `login_cubit_test.dart`

Unit tests for `LoginCubit` (`lib/features/auth/login/logic/cubit/login_cubit.dart`) — verifies
the state transitions it emits in response to `LoginRepo` results, without touching any HTTP or
Flutter widget code.

## What's mocked

- **`LoginRepo`** — mocked with `mockito`'s `@GenerateMocks([LoginRepo])` (generated into
  `login_cubit_test.mocks.dart`, regenerate via `dart run build_runner build`). The cubit only
  depends on the repo's public interface, so no other seams are needed here.
- State assertions use [`bloc_test`](https://pub.dev/packages/bloc_test)'s `blocTest`, which is
  the standard way to assert an exact sequence of emitted states for a `Cubit`/`Bloc`.

## Scenarios covered

- Initial state is `LoginState.initial()`.
- `emitLoginStates()` (email/password login):
  - Success → emits `[loading, success(data)]`, and the repo is called with a `LoginRequestBody`
    built from `mailController.text` / `passwordController.text` (verified via `captureAny`).
  - Failure → emits `[loading, failure(apiErrorModel)]` with the repo's error message intact.
- `loginWithGoogle(idToken)`:
  - Success → emits `[loading, success]`, correctly carrying through `isNewUser` from the repo.
  - Failure → emits `[loading, failure]`.

## Testability fix this test suite depends on

`LoginCubit` was declared as `extends Cubit<LoginState>` — a **raw generic type**, so `T` in
`LoginState<T>` silently resolved to `dynamic` everywhere. That made `bloc_test`'s state matchers
(`isA<Success<LoginResponse>>()`) fail even though the runtime behavior was correct, because the
emitted states were typed `LoginState<dynamic>` instead of `LoginState<LoginResponse>`. Fixed by
changing the declaration to `extends Cubit<LoginState<LoginResponse>>`. See `CLAUDE.md` → Known
Bugs Fixed.

## A note on `blocTest` + `TextEditingController`

Each `blocTest` block builds its own `LoginCubit` inside `build:` (backed by the shared
`mockLoginRepo` instance from `setUp`) and lets `blocTest` close it automatically at the end of
the test. Don't add a file-level `tearDown(() => loginCubit.close())` alongside `blocTest` — the
cubit's `close()` disposes its `TextEditingController`s, and `blocTest` already closes the bloc
it was handed, so a second manual close throws "used after being disposed". The one plain `test()`
in this file (initial state) closes the cubit itself since `blocTest` isn't involved there.

## Running

```bash
flutter test test/features/auth/login/logic/cubit/login_cubit_test.dart
```
