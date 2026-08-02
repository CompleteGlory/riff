# `app_router_test.dart`

## What it covers

`AppRouter.generateRoute` — that every destination reachable from a push
notification exists, receives its arguments, and shares the app-lifetime cubits
rather than creating (and later closing) its own.

- `Routes.notifications` provides the **same** `NotificationsCubit` instance
  registered in GetIt.
- `Routes.chatsList` provides the **same** `ChatsListCubit` instance.
- `Routes.flaggedComment` / `Routes.flaggedPost` unpack the `NotificationRoute`
  argument into the screen's `commentId` / `postId` / `flagTitle` / `flagBody`,
  and still build when no argument is supplied.
- Every route name under test resolves to a `MaterialPageRoute`; an unknown name
  falls back to onboarding.

## What's mocked

- Only the two singletons the routes under test resolve are registered in GetIt.
  Constructing `NotificationsCubit` / `ChatsListCubit` is side-effect free —
  nothing reaches the network unless `load()` is called, which no route does.
- Screens are **not mounted**. `route.builder(context)` returns the widget
  without running `initState`, which keeps Firebase and the network out.
- `providedCubit` mounts just the `BlocProvider` around a probe child (via
  `SingleChildStatelessWidget.buildWithChild`) to read back which instance it
  exposes — asserting identity without booting the screen underneath.

## Regressions locked in

**Closed GetIt singletons.** `BlocProvider(create: ...)` closes whatever it
created when its route pops, and a closed bloc can never emit again. Because
GetIt keeps handing back the same dead instance, one bad provider poisons the
feature for the rest of the process. Both the Home route and the
push-notification routes did this:

- `NotificationsCubit` → "mark all as read" silently stopped working, but only
  after the user had opened and left a notification screen.
- `ChatsListCubit` → the chat list froze after switching accounts or opening a
  chat from a notification.

Every provider is `.value` now, and the cubits additionally carry
`AppScopedCubit` so a future `create:` can't reintroduce it — see
`test/core/logic/app_scoped_cubit_test.dart`.
