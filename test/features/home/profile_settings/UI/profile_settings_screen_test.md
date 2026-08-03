# `profile_settings_screen_test.dart`

## What it covers

Where the screen opens, and what saving touches.

- From the drawer (`scrollToPreferences: false`) it starts at the top of the
  form, on Full Name.
- From the "Complete your profile" notification (`scrollToPreferences: true`) it
  opens with the genres section at the top of the viewport — the nudge is
  entirely about genres and instruments, so landing on the name/username/email
  block leaves the user hunting for what they just tapped.
- Saving calls `refreshProfile()` on the **shared** `HomeCubit`, which is what
  makes a newly-picked instrument show on the profile tab without a restart.

## What's mocked

- `HomeRepo` — one mockito mock backing both `HomeCubit` and
  `ProfileSettingsCubit`, so `verify(repo.getMe())` reads as "the profile was
  re-fetched".
- Nothing else. The screen is pumped the same way `Routes.profileSettings`
  builds it: `BlocProvider.value` for the caller's `HomeCubit`, a fresh
  `ProfileSettingsCubit` beside it.

## Gotchas

- **Don't read `find.byType(Scrollable).last`.** Every `TextFormField`
  contributes its own *horizontal* editable scrollable, and those come after the
  form's in tree order. Reading one gives a permanent offset of `0`, so a broken
  scroll passes a `expect(offset, 0)` test and fails a `greaterThan(0)` one for
  the wrong reason — which is exactly what happened while writing this. The
  `formScroll` helper resolves the first `Scrollable` under the
  `SingleChildScrollView` instead.
- **The screen is pushed on top of a placeholder, not pumped as `home:`.** It
  calls `Navigator.pop(context, true)` after a successful save, and popping the
  only route on the stack isn't something a test can assert against.
- The scroll is an animated `Scrollable.ensureVisible` fired from a post-frame
  callback in `initState` (the anchor doesn't exist until the form has been laid
  out once). `pumpAndSettle` covers both the route transition and the scroll.

## Why the shared-cubit assertion matters

`ProfileSettingsScreen` reaches for `context.read<HomeCubit>()` inside a
`try/catch` that swallows the failure — the screen can be opened from outside
the home shell. So handing the route a *fresh* `HomeCubit` compiles, navigates,
saves, and shows the success snackbar, while the profile tab silently keeps the
old genres. `verify(repo.getMe()).called(1)` after `clearInteractions` is what
pins the refresh actually happening.

See also
[notifications_screen_test.md](../../notifications/UI/notifications_screen_test.md)
for the notification end of the same flow.
