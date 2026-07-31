# `notifications_screen_test.dart`

## What it covers

That tapping "Mark all read" updates the list **on screen, immediately** —
no pull-to-refresh, no waiting on the network.

- The unread styling clears on the very next frame, with no re-fetch.
- It clears *before* the server has answered (optimistic).
- It comes back, with an error snackbar, if the server rejects it.
- A later refresh keeps them read.

## What's mocked

- `NotificationsRepo` — mockito mock (`@GenerateMocks`).
- `SocketService` — hand-written fake subclass.
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
