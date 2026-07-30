# `phone_verify_screen_test.dart`

Widget tests for `PhoneVerifyScreen` (step 1: enter phone number). Unlike every other auth screen
in this repo, its state-to-UI reactions are wired with a single inline `BlocConsumer` rather than
a dedicated `BlocListener` widget, so these tests drive the cubit directly and assert on the
resulting button label / snackbar / navigated screen instead of pumping an isolated listener
widget.

## What's mocked

- **`PhoneVerifyRepo`** — mocked (reusing the mock generated for `phone_verify_cubit_test.dart`)
  so a real `PhoneVerifyCubit` can be provided.

## Scope note: `IntlPhoneField` input isn't driven

These tests call `cubit.sendOtp(...)` directly rather than typing into the third-party
`IntlPhoneField` widget and tapping the button — validating that specific package's input/country
picker behavior is out of scope here. What's covered is everything downstream of a phone number
reaching the cubit: the loading label, error snackbar (including the `PHONE_ALREADY_TAKEN`
special case), and the navigation to `PhoneOtpScreen` on success.

## Scenarios covered

- Renders the initial "Send OTP via WhatsApp" button.
- Shows the "Sending…" label while the cubit is `Loading`.
- A `409` (phone already taken) shows the localized "already taken" snackbar, and a `503`
  (the API could not hand the OTP to WhatsApp) shows the localized
  `phoneOtpWhatsappUnavailable` snackbar. The `503` test also asserts the server's English
  message is **not** rendered — the cubit converts both statuses to sentinels that
  `_localizedError` maps to ARB strings, so a regression that leaks raw server text fails here.
  Any other failure still shows the server's raw message.
- Success navigates to `PhoneOtpScreen` with the phone number interpolated into its subtitle.

## Two timing pitfalls this test suite caught

1. **`BlocConsumer`'s `builder` needs two pumps, not one.** Calling `cubit.sendOtp(...)` without
   awaiting it emits `Loading` synchronously, but delivering that state to the `BlocConsumer`'s
   stream subscription happens on a microtask (one `pump()` to flush it), and the subscription's
   `setState()` call — since it's firing from a microtask callback, not during an active frame —
   only *schedules* a rebuild rather than rebuilding immediately (a second `pump()` to actually see
   the updated button label). A single `pump()` reports the old, pre-loading UI.
2. **Never call `pumpAndSettle()` after triggering success.** `PhoneOtpScreen` starts a real
   `Timer.periodic(const Duration(seconds: 1), ...)` for its 60-second resend countdown, and its
   blinking-cursor widget runs an indefinitely-repeating `AnimationController`. Both keep
   scheduling new frames forever, so `pumpAndSettle()` never settles — it either times out slowly
   or, worse, hangs the process (see `reset_password_bloc_listener_test.md` for what an unbounded
   hang looks like). Use a bounded `tester.pump(someDuration)` instead once you've triggered a
   transition onto `PhoneOtpScreen`.

## Running

```bash
flutter test test/features/auth/phone_verify/UI/phone_verify_screen_test.dart
```
