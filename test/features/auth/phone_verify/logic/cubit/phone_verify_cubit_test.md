# `phone_verify_cubit_test.dart`

Unit tests for `PhoneVerifyCubit`. Different shape from the other auth cubits: its state class
(`PhoneVerifyState`) is a plain abstract class hierarchy, not a `freezed` union, so there's no
`.when()`/`.whenOrNull()` — states are matched with `isA<T>()` / `is` checks, both in production
code and in these tests.

## What's mocked

- **`PhoneVerifyRepo`** — mocked with `@GenerateMocks([PhoneVerifyRepo])`.

## Scenarios covered

- Initial state is `PhoneVerifyInitial`.
- `sendOtp`: normalizes the phone number before calling the repo and before storing it on
  `cubit.phoneNumber`; emits `[loading, otpSent(normalizedNumber)]`. A `409` from the repo maps to
  the sentinel message `'PHONE_ALREADY_TAKEN'` (matching the UI's special-cased snackbar text);
  any other failure passes the server's message through as-is.
- `verifyOtp`: emits `[loading, success]` using the phone number captured by an earlier `sendOtp`
  call (there's no setter — the only way to get a phone number into the cubit from a test is to
  actually call `sendOtp` first); guards against being called with **no** phone number yet (no-op,
  verified via `verifyNever`); guards against being called again while a verification is already
  **in flight** — this one is seeded directly into `PhoneVerifyLoading` via `blocTest`'s `seed:`
  parameter rather than by racing two real async calls.
- `resetToInitial()` emits `PhoneVerifyInitial` from any prior state.

## Running

```bash
flutter test test/features/auth/phone_verify/logic/cubit/phone_verify_cubit_test.dart
```
