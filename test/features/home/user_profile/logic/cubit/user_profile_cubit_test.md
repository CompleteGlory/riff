# `user_profile_cubit_test.dart`

## What it covers

That leaving someone's profile while it is still loading does not crash.

`loadProfile` awaits **twice** — the profile, then the posts — and then emits
from inside `.when` callbacks. Backing out during that window closes the cubit
while its result handlers are still queued, and every emit below throws:

```
StateError: Bad state: Cannot emit new states after calling close
  at BlocBase.emit (bloc_base.dart:100)
  at UserProfileCubit.loadProfile (user_profile_cubit.dart:42/44/48)
```

Fatal, 3 users, in production.

| Case | Expected |
| --- | --- |
| both requests succeed | `UserProfileLoaded` |
| closed mid-load, profile then succeeds | completes, no throw |
| closed mid-load, profile then fails | completes, no throw |

The failure branch is a separate test because it is a separate `emit` on a
separate path, and fixing only the success branch would have looked correct.

## Why a Completer

The crash needs the cubit closed *between* the request starting and its result
arriving. A stubbed `Future.value` resolves too early to reproduce that, so the
repo is stubbed with a `Completer` the test completes by hand, after `close()`.

Removing the `isClosed` guard fails both tests with the exact production
message — the emit is genuinely reached, not merely attempted.

## What's mocked

`UserProfileRepo` and `FollowRepo`. No widgets, no platform channels.

## Note

`removePostLocally` in the same cubit already guarded with `isClosed`; only
`loadProfile` did not. Worth knowing when reading the file — the guard being
present nearby is exactly why its absence here was easy to miss.
