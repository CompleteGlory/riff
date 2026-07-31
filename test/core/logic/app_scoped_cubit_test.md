# `app_scoped_cubit_test.dart`

## What it covers

The `AppScopedCubit` mixin, which marks a cubit whose lifetime is the **app**,
not a route.

- `close()` is a no-op; `disposePermanently()` really closes;
  `isPermanentlyClosing` only flips on a deliberate dispose.
- A mixed-in cubit survives `BlocProvider(create:)` *and* `BlocProvider.value`
  route disposal, and still drives widgets after the round-trip.
- A plain cubit is included as the baseline for contrast.

## What's mocked

Nothing — two tiny local counter cubits and a real `Navigator`.

## Testing gotchas

- `blocTest` and anything expecting `emitsDone` need `disposePermanently()`;
  plain `close()` deliberately leaves the stream open.
- Assert with `pumpAndSettle()`, not a single `pump()`, after emitting: the
  state stream is asynchronous and one frame can land before the `BlocBuilder`
  has seen the new value.

## Why this exists

`NotificationsCubit`, `ChatsListCubit` and `CreatePostCubit` are GetIt
singletons. Handing one to `BlocProvider(create: ...)` closes it when that route
pops, and GetIt then keeps returning the closed instance forever — every later
`emit` hits an `if (!isClosed)` guard and does nothing, with no error anywhere.
That is what broke "mark all as read" and froze the chat list.

The call sites were fixed to use `.value`, but this bug had already been
introduced twice by relying on that discipline. The mixin makes the mistake
impossible instead of merely absent.
