# `account_settings_phone_tile_test.dart`

Widget tests for the "confirm your phone number" entry in `AccountSettingsScreen` — the entry
that appears only while the user's number is unconfirmed.

## Scope note: only the phone entry

The privacy switch on the same screen is deliberately untested here. `_togglePrivacy()` reaches
`getIt<FollowCubit>()` directly from the widget rather than taking it through the constructor,
so covering it would mean registering the whole DI graph — the same reason
`new_user_onboarding_screen.dart` is excluded in CLAUDE.md. If that switch grows real logic, give
it constructor injection first.

## What's mocked

- **Nothing.** The screen takes `initialPhoneVerified` as a plain constructor argument, so the
  state under test is passed in directly. The destination is stubbed as a named route (below).
- `SharedPreferences.setMockInitialValues({})` in `setUp` — widgets here can reach
  SharedPreferences on the way to their theme/locale state, and without it the platform channel
  never resolves and the test **hangs** rather than failing.

## How the navigation is stubbed

`pumpApp`'s `routes` map registers a single stub at `Routes.confirmPhone` that immediately pops a
configurable result. Because it is the *only* named route registered, a tap that resolves at all
is itself proof the screen pushed that specific route — no navigator-observer spy needed.

## Scenarios covered

- Verified → no entry, and the rest of the screen (Change Password) is untouched.
- Unverified → section header, title and subtitle all render.
- **Default is verified.** Constructing the screen with no argument hides the entry. This is the
  back-compat guard: `phone_verified` absent from `GET /api/users/me` must read as "unknown, stay
  quiet", never as "unverified, nag everyone".
- Flow pops `true` → the entry retires immediately, without waiting for an app relaunch.
- Flow pops `null` (user backed out) → the entry stays. Dismissing is not confirming, and the
  check has to distinguish "no result" from a real `true`.

## Gotcha this suite caught

`_SectionHeader` renders `title.toUpperCase()`, so asserting on the raw ARB string finds nothing.
Match `S.current.confirmPhoneSection.toUpperCase()` — the rendered text, not the source string.

## Running

```bash
flutter test test/features/home/account_settings/UI/account_settings_phone_tile_test.dart
```
