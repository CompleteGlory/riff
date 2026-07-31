# `conversation_dedupe_test.dart`

## What it covers

`dedupeConversations` and `isRicherThan` — collapsing the duplicate direct
conversations some accounts already carry.

- Clean lists pass through untouched, in order; groups never collapse into each
  other or into a direct chat.
- Two direct conversations with the same person collapse to **one**, keeping
  whichever holds the real conversation. The tie-break ladder is tested rung by
  rung: has a latest message → more recent `lastMessageAt` → higher unread count
  → older `createdAt` (the original, not the accidental second row).
- The survivor keeps the position of the first copy, so the list doesn't
  reorder under the user mid-scroll.
- Direct conversations with **no** other user (the orphans the old decline
  handler left behind) are not folded together — they have no user to key on.

## What's mocked

Nothing — plain `Conversation` values.

## Gotcha

The local `Conversation groupConv(...)` helper is deliberately not called
`group`: that shadows `flutter_test`'s `group` and every `group(...)` block
fails to compile with a confusing "too many positional arguments".

## Regressions locked in

The reported symptom: a person appears twice in the chat list, once with the
messages and once as an empty thread. Two server-side causes, both now fixed —
`POST /chat/conversations/direct` doing a non-atomic check-then-create, and
declining a message request deleting only the recipient's participant row so
the existence check could no longer match. Accounts that already have the
duplicated rows would keep seeing them regardless, so the client collapses them
on the way in.
