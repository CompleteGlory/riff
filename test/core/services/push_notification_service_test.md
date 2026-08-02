# `push_notification_service_test.dart`

## What it covers

Navigation performed by `PushNotificationService` when a push notification is
tapped — the full matrix of "open the app from a notification" cases:

- **Simple destinations** — notifications list, flagged comment, flagged post,
  including that the resolved `NotificationRoute` is passed along as the route
  argument.
- **Chat taps** — chats list first, then the conversation on top of it; the
  fetched `Conversation` is the route argument; a conversation that can't be
  read stops at the list instead of throwing; a message for the conversation
  the user is already looking at pushes nothing.
- **Taps the app isn't ready for** — parked while signed out and replayed by
  `flushPendingRoute()` after login (replaying twice still pushes once), and a
  cold-start tap that waits for the navigator to mount.
- **Duplicate taps** — the same `messageId` routes once; different ids both
  route; a message with no id always routes.

## What's mocked

- **The navigator** is real, wired to `NavigationService.navigatorKey`, but
  every destination is a stand-in built by a catch-all `onGenerateRoute`. A
  `NavigatorObserver` records the pushed `RouteSettings`. That is deliberately
  the assertion level: *which route name, in what order, with what arguments* —
  the real screens want Firebase and the network.
- `ChatRepo` — mockito mock (`@GenerateMocks`).
- `ChatSocketService` — the real object; `joinConversation` only records the id
  locally when no socket is open, which is exactly the "already viewing this
  chat" signal the test needs.
- Sign-in state is `SharedPreferences.setMockInitialValues` with/without tokens.

## Timing gotcha

`navigateTo` waits on `NavigationService.waitUntilReady`, which polls on real
timers. The cold-start test therefore drives the waiting inside
`tester.runAsync` and pumps the app in between — under the default fake-async
clock the poll would never fire and the test would hang rather than fail.

## Regressions locked in

- **The dead navigator key.** This class used to own a second
  `GlobalKey<NavigatorState>`, and *that* was the one `MaterialApp` was built
  with — so every `NavigationService` call elsewhere in the app (notably the
  401 handler's redirect to login) resolved to `null` and did nothing.
- **The fixed 800 ms cold-start delay.** A slower boot meant the navigator still
  wasn't there when the timer fired, and the tap was dropped.
- **Authenticated screens pushed onto the login stack** when a tap arrived while
  signed out.
- **Double-routing.** `getInitialMessage()` and `onMessageOpenedApp` can both
  fire for one tap on some Android launches, stacking two copies of the screen.
