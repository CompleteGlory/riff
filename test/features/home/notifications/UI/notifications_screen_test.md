# `notifications_screen_test.dart`

## What it covers

**Mark all read** — that tapping it updates the list **on screen, immediately**
— no pull-to-refresh, no waiting on the network.

- The unread styling clears on the very next frame, with no re-fetch.
- It clears *before* the server has answered (optimistic).
- It comes back, with an error snackbar, if the server rejects it.
- A later refresh keeps them read.

**The complete-profile nudge** — that it lands on Profile Settings and then
clears itself.

- "Set up" opens the `Routes.profileSettings` route.
- It carries the loaded `UserProfile` and the *shared* `HomeCubit`.
- It asks the form to open scrolled to the genres/instruments pickers
  (`scrollToPreferences: true`); the scroll itself is covered by
  [profile_settings_screen_test.md](../../profile_settings/UI/profile_settings_screen_test.md).
- Tapping anywhere on the row does the same thing as the button.
- The notification is deleted once the user comes back from settings — and
  *only* then. Merely rendering the list must not consume it.

## What's mocked

- `NotificationsRepo`, `HomeRepo` — mockito mocks (`@GenerateMocks`).
- `SocketService` — hand-written fake subclass.
- `Routes.profileSettings` — stubbed through `pumpApp`'s `routes` map, so the
  real `ProfileSettingsScreen` (which wants its own cubit and the network) never
  builds. The stub records `ModalRoute.of(context)!.settings.arguments`, which is
  how the argument assertions get at the `ProfileSettingsArgs` it was pushed
  with, and carries a "go back" button — the nudge is deleted after the push
  *returns*, so the test needs a way to pop it.
- `NotificationsScreen.notificationsDenied` — the screen used to call
  `FirebaseMessaging.instance.getNotificationSettings()` directly in
  `initState`, which cannot run in a widget test. It is now an injectable
  callback defaulting to the real Firebase call, following the pattern
  established in the login tests.

## What "read" looks like on screen

For follow / like / comment notifications the *only* visual difference is the
row's background tint — read rows are transparent, unread ones carry a ~6–8%
accent wash. (Admin and flagged tiles also drop a coloured dot.) So
`unreadRowCount` counts `Container`s with a non-transparent colour rather than
looking for a label.

## Timing gotcha

State is seeded with `silentRefresh()`, not `load()`. `load()` also starts the
30-second poll, and the widget-test binding fails with "a timer is still
pending" before `tearDown` gets a chance to cancel it. `silentRefresh()` is also
exactly what a pull-to-refresh does, which is what the last test needs.

## Regressions locked in

Two separate causes of "I have to refresh before they show as read":

1. `markAllRead` used to emit only *after* awaiting the request, and swallowed
   every error — so a failure was indistinguishable from a success that hadn't
   happened yet. It is now optimistic and reports its result.
2. A fetch already in flight could land in the window between the optimistic
   update and the server committing, and repaint every row as unread. See the
   `a fetch in flight does not undo a local change` group in
   [notifications_cubit_test.md](../logic/cubit/notifications_cubit_test.md).

And the nudge's destination: "Set up" used to push `InstrumentsScreen` with an
`onFinish` that popped twice to unwind the genres and instruments screens it had
stacked, which is not where those fields are edited from anywhere else in the
app.

## Why the HomeCubit assertion matters

`Routes.profileSettings` takes a `(UserProfile, HomeCubit)` record, and
`ProfileSettingsScreen` calls `refreshProfile()` on that cubit after saving so
the home shell reflects the change without a restart. Handing it a *fresh*
cubit would compile, navigate, and look completely fine — the home shell would
just silently keep showing stale data. Hence `same(homeCubit)` rather than
`isA<HomeCubit>()`.

The notifications screen is also a push-notification destination, and
`Routes.notifications` provides only the notifications cubit — no `HomeCubit`
above it. `_openProfileSettings` falls back to a throwaway `getIt<HomeCubit>()`
there and closes it again on the way out. That fallback path isn't covered here:
it needs a configured GetIt, and the shared path is the one users actually take.
