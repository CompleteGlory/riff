# `navigation_service_test.dart`

## What it covers

`NavigationService` — the app's single context-free navigation entry point.

- **Readiness** — `isReady` / `waitUntilReady`: false before `MaterialApp` is
  built, resolves once the navigator mounts, waits for a navigator that appears
  late, and gives up after the timeout instead of hanging forever.
- **`goToLoginAndClearStack`** — lands on login with an empty back stack,
  collapses concurrent calls into one navigation, and is callable again once the
  first redirect finishes.

## What's mocked

Nothing. A real `MaterialApp` is pumped with `NavigationService.navigatorKey`
and lightweight named stand-ins for `/start`, `/second` and `Routes.login`.

`NavigationService.readyTimeout` is shortened in `setUp` so the no-navigator
case doesn't sit for the production 10 seconds.

## Timing gotcha

`waitUntilReady` polls on real timers, so the two tests that actually wait
(navigator appears late, navigator never appears) do their waiting inside
`tester.runAsync`. Under the default fake-async clock the poll never fires and
the test hangs instead of failing — which is exactly what happened the first
time these were written.

## Regressions locked in

- **The unwired key.** `MaterialApp` was built with
  `PushNotificationService.navigatorKey` while the 401 interceptor pushed
  through `NavigationService.navigatorKey`, whose `currentState` was therefore
  always `null`. Forced sign-outs never actually reached the login screen; the
  app just sat there with every request failing. There is now one key, and these
  tests exercise it end to end.
- **Stacked login screens.** Several concurrent 401s each fired their own
  redirect.
