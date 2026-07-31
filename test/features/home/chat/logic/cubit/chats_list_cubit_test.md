# `chats_list_cubit_test.dart`

## What it covers

`ChatsListCubit`'s use of the dedupe, on every path that puts a conversation
into the list:

- **`load`** — collapses a duplicated person into the thread with the messages,
  leaves clean lists untouched, dedupes message requests too, and surfaces a
  load failure as `ChatsListError`.
- **`prependConversation`** — adds someone new to the top, ignores a
  conversation already present by id, and does not add a second row for someone
  already listed under a *different* conversation object (which is what
  starting a chat from search returns).
- **`acceptRequest`** — moves the conversation from requests into the list, and
  doesn't duplicate one that a refresh already moved across.

## What's mocked

`ChatRepo` — mockito mock (`@GenerateMocks`). No socket involved.

## Timing gotcha

`tearDown` uses `disposePermanently()`: `ChatsListCubit` mixes in
`AppScopedCubit`, which ignores plain `close()` on purpose.

## Regressions locked in

See [conversation_dedupe_test.md](conversation_dedupe_test.md) for the origin of
the duplicates. This file covers the wiring — the dedupe being applied on
`load`, `prependConversation` *and* `acceptRequest`, not just the first one.
