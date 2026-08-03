# `conversation_ordering_test.dart`

Covers `sortConversationsByRecency` — the pure function `ChatsListCubit` uses
to re-sort the chat list after a message is deleted.

## Why this exists as its own function

Every other event in chat moves a conversation to the **top**: a new message
arrives, the row jumps to position 0, and `ChatsListCubit.onNewMessage` does
that with an explicit `removeAt`/`insert` rather than a sort — deliberately, so
that the socket and REST payloads serializing `created_at` differently (naive
vs. UTC `Z`) can't misplace it.

Deleting a message is the one case that moves a conversation the *other* way.
If it was the newest message, the conversation now sorts by whatever is left,
which may be older than several conversations below it. That can't be expressed
as "move to position 0", so it genuinely needs a sort — and a sort is exactly
the thing that was avoided elsewhere, which makes it worth isolating and
testing on its own.

## What it covers

- most recent message first
- a conversation with **no** messages (never spoken in, or its only message was
  just deleted) falls back to `created_at` rather than sinking to the bottom
- equal timestamps break on the newer conversation
- the input list is not sorted in place — it belongs to a state object
  something else may still be holding
- an empty list

## Mocks

None. `Conversation` is constructed directly; the function touches only
`lastMessageAt` and `createdAt`.
