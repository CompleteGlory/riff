# `chats_list_screen_test.dart`

## What it covers

That the chat list can be searched. Specifically, that `UserSearchCubit` is
reachable from the widgets that read it.

| Case | Expected |
| --- | --- |
| screen builds, no query | no exception, search field present |
| type a query | **no exception** |
| clear the query | no exception |

## Why this exists

`ProviderNotFoundException` — fatal, 72 events, 3 users, in production. Nobody
could search for someone to chat with.

`build` wraps the screen in `BlocProvider<UserSearchCubit>.value` and then
calls `_buildBody(context, isDark)`. That passes the context from **above** the
provider, so anything inside using it looks the cubit up from the wrong place
and walks straight past it. `create_group_screen` has the identical code and
never failed, because it goes through `Builder(builder: _buildBody)` — its
context is below the provider. One `Builder` was the whole difference.

## Why it survived the earlier fix

This is the second time this bug class has appeared here. The first was caught
by an audit: a `BlocProvider` created inside `build` while a State method called
`context.read`. That fix introduced the `_userSearch` field and
`BlocProvider.value` — and left this second, subtler instance in place, because
there was no test.

**`builds without a search query` passes even with the bug present.** That is
the point of having all three: the only `context.watch<UserSearchCubit>()` sits
behind `if (_query.isNotEmpty)`, so the screen renders perfectly and then
throws the instant someone types. A test that only pumps the screen proves
nothing here.

Reintroducing the bug fails `typing a query…` and `clearing the query…` with
the exact production exception, and leaves the first test green.

## What's mocked

`ChatRepo` (so `load()` resolves to empty lists) and `SearchRepo` (registered
in GetIt behind `UserSearchCubit`, which the screen resolves itself).
`SharedPreferences` is mocked because `_loadMyId` reads it — without that the
platform channel never resolves and the test hangs rather than failing.

## Gotcha

No `pumpAndSettle` anywhere. The screen shows a `LinearProgressIndicator` while
a search runs and a `CircularProgressIndicator` while the list loads; neither
ever settles, so `pumpAndSettle` hangs instead of reporting. Bounded
`pump(Duration)` throughout.
