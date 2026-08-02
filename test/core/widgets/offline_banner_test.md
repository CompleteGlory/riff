# `offline_banner_test.dart`

## What it covers

`OfflineBanner`, the app-wide connection bar wrapped around the navigator in
`RiffMaterialApp.builder`.

- nothing is rendered while the connection is fine — no reserved space, no
  layout shift on a healthy app;
- the bar appears when connectivity drops, with the app still rendered below it;
- recovery is confirmed with a green "back online" bar that then disappears on
  its own after `OfflineBanner.recoveryNoticeDuration`;
- the bar **displaces** the app rather than overlaying it.

## What's mocked

Nothing but the reachability probe (`ConnectivityService.probe`). The widget
subscribes to the real singleton, so the test drives it the same way the network
layer does.

## Gotchas

- **A test that ends while offline must stop the probe inside the test body.**
  The service keeps a pending backoff `Timer` while offline, and the test binding
  fails on outstanding timers *before* user `tearDown`s run — so `stopProbing()`
  is called at the end of those tests rather than from `tearDown`.
- `ConnectivityService.resetInstanceForTest()` in both `setUp` and `tearDown`:
  it is a singleton and the offline verdict would otherwise leak into the next
  test.
- Two `pump`s after a status change: one to deliver the stream event, one to let
  the 250ms `AnimatedSwitcher` finish. `pumpAndSettle` also works here but not
  once a screen with a repeating animation is underneath.

## Regression locked in

The first implementation floated the bar over the navigator in a `Stack`. It sat
on top of every screen's `AppBar` — hiding the title and the chat/notification
actions exactly when the user most wants to see what still works. The layout
assertion is what keeps it displacing content instead.
