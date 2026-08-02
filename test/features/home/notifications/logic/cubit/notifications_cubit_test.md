# `notifications_cubit_test.dart`

## What it covers

`NotificationsCubit.markAllRead`, plus the singleton-lifetime behaviour behind
the "mark all as read sometimes works, sometimes doesn't" report.

- **`markAllRead`** — clears the badge and marks every item read on success;
  rolls the list back and returns `false` when the server rejects it; updates
  optimistically *before* the request resolves; still calls the server when
  nothing is loaded yet.
- **Surviving route disposal** — `close()` (what `BlocProvider` calls) leaves
  the cubit usable, including its polling timer.
- **Stale fetches** — a `getNotifications()` that was already in flight when the
  user marked everything read (or deleted a row) is dropped instead of emitted;
  one that starts afterwards is applied normally.
- **`reset`** — wipes state for the next user without killing the singleton.

## What's mocked

- `NotificationsRepo` — mockito mock (`@GenerateMocks`).
- `SocketService` — a hand-written fake subclass. Mocking it with mockito would
  mean stubbing the whole surface just to stop `load()` opening a websocket.
- `SharedPreferences.setMockInitialValues({})` in `setUp` — `load()` reaches
  storage through the session manager on its way to the socket.

## Timing gotcha

`tearDown` uses `disposePermanently()`, not `close()`. An `AppScopedCubit`
ignores `close()`, and the 30-second polling timer started by `load()` has to be
cancelled or the test binding fails with a pending timer.

## Regressions locked in

- **Silent failure.** `markAllRead` used to emit only *after* awaiting the
  request and swallowed every error, so a failed call was indistinguishable from
  a successful one — the badge just stayed put with no explanation. It is now
  optimistic, rolls back, and returns a result the screen surfaces.
- **The closed singleton.** The notifications route provided this GetIt
  singleton with `BlocProvider(create:)`, so popping it closed the cubit
  permanently. Every later `markAllRead()` hit `if (!isClosed)` and did nothing.
  The user-visible symptom — it works until you've opened and left the
  notifications screen once, then never again — is exactly "sometimes it works,
  sometimes it doesn't".
- **A background fetch undoing the local update.** The optimistic update lands
  immediately, but the 30-second poll — or the `silentRefresh()` HomeLayout runs
  when you come back from the notifications screen — could return server data
  from *before* the mark-all-read committed and repaint every row as unread.
  That reads as the button doing nothing, right up until a manual refresh
  finally sticks. Local changes now bump an epoch counter and any fetch that
  started before the bump discards its result.
