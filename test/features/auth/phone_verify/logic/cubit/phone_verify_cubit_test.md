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
  the sentinel message `'PHONE_ALREADY_TAKEN'`, and a `503` maps to `'WHATSAPP_UNAVAILABLE'`
  (both resolved to localized text by `_localizedError` in `phone_verify_screen.dart`); any other
  failure passes the server's message through as-is.

  The `503` case is the API reporting that it could not hand the OTP to WhatsApp. It exists
  because the server used to answer `200 "OTP sent via WhatsApp"` even when its WhatsApp client
  was disconnected — the code only ever reached a log line, so the app advanced to the code-entry
  screen for an OTP that was never delivered. The sentinel is asserted here rather than the
  server's English string precisely so that a regression to raw pass-through text fails.
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
