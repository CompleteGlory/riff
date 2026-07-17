# `phone_verify_repo_test.dart`

Unit tests for `PhoneVerifyRepo` — notable because, unlike every other auth repo, it talks to a
bare **`Dio`** instance directly rather than the retrofit-generated `ApiService` (there's no
`ApiService` method for these two endpoints).

## What's mocked

- **`Dio`** — mocked with `@GenerateMocks([Dio])`. `PhoneVerifyRepo` calls `_dio.post(url, data:
  {...})` directly, so the test verifies the exact URL and JSON body sent, using
  `captureAnyNamed('data')`.

## Scenarios covered

- `sendOtp`: strips all non-digit characters from the phone number before posting (e.g.
  `'+20 100-123-4567'` → `'201001234567'`); returns failure when the request throws.
- `verifyOtp`: posts the normalized phone number and the OTP; returns failure with the server's
  message on a bad response.

## Running

```bash
flutter test test/features/auth/phone_verify/data/repos/phone_verify_repo_test.dart
```
