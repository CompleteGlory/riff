# `user_profile_phone_fields_test.dart`

Unit tests for the phone fields on `UserProfile` — the model `HomeRepo.getMe()` parses
`GET /api/users/me` into. `phoneVerified` is the single input deciding whether account settings
shows the "confirm your phone number" entry, so its parsing is worth pinning independently of any
widget.

Note the model lives in `lib/features/home/profile/UI/profile_screen.dart` rather than under
`data/models/` — it predates this change and was left where it is.

## What's mocked

Nothing — this is pure `fromJson` parsing.

## Scenarios covered

- `phone_number` and `phone_verified` are read off the response.
- `phone_verified: false` parses as unverified.
- **Absent `phone_verified` defaults to `true`.** This is the one that matters: a client running
  against an API predating these fields must not conclude every user is unverified and prompt all
  of them. Absent means "unknown", and unknown stays quiet. The corresponding widget-level guard
  is in [account_settings_phone_tile_test.md](../account_settings/UI/account_settings_phone_tile_test.md).
- `phone_number: null` alongside `phone_verified: false` — the real shape for a user who has never
  submitted a number.
- The pre-existing fields still parse, so adding these didn't disturb the rest of the payload.

## Running

```bash
flutter test test/features/home/profile/user_profile_phone_fields_test.dart
```
