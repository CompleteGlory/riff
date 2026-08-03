# `chat_cubit_test.dart`

## What it covers

`ChatCubit`'s socket lifecycle — the "I opened the app from a message
notification and couldn't send anything until I restarted" bug.

- **`open`** — loads history, brings the socket up, then joins the room;
  records the room even when the socket is down (so a later reconnect re-joins);
  surfaces a load failure as `ChatError`.
- **`sendText`** — reports success and what was sent; reports **failure** when
  the socket can't be reached or no conversation is open.
- **`ensureConnected`** — reconnects and re-joins the open conversation; reports
  failure without joining when the socket stays down.
- **Read receipts** — reopening the chat picks up the status the server reports;
  a `read` event upgrades every message; a `message_id` scopes the upgrade to
  one; an already-read message is never downgraded; an event for another
  conversation is ignored.

## What's mocked

- `ChatRepo` — mockito mock (`@GenerateMocks`).
- `ChatSocketService` — a hand-written fake subclass recording
  `ensureConnected` calls, room joins and sent messages, with a `connects` flag
  to simulate a socket that won't come up. Subclassing keeps the real
  constructor (and its stream controllers) intact while overriding only the
  methods the cubit calls.
- `SharedPreferences.setMockInitialValues({})` in `setUp`.

## Regressions locked in

- **Handshaking with an expired token.** `ChatGateway.handleConnection` verifies
  the access token and disconnects the client when it fails. Access tokens live
  15 minutes, so opening the app from a push notification — by definition after
  a pause — handed the gateway a dead token. HTTP recovered through the 401
  interceptor, so message history loaded normally and the screen looked fine;
  the socket never recovered, and every `send_message` emit went into the void
  until the app was restarted (by which point the interceptor had refreshed the
  stored token). `open()` now brings the socket up through
  `SessionManager.validAccessToken()` first.
- **Checkmarks resetting to one tick.** Read receipts only existed as a live
  socket event, and the REST serializer had no `status` field — so
  `MessageStatusX.fromString(null)` fell through to `sent` and every message
  showed a single check again as soon as the sender reopened the chat, however
  long ago it had been read. The API now derives status from
  `conversation_participants.last_read_at` and sends it with every message; see
  [message-status.spec.md](/Users/magd/apis/riff/src/modules/chat/message-status.spec.md).
- **Fire-and-forget sends.** `sendText` returned `void` and emitted into
  whatever socket happened to be there. The composer cleared either way, so the
  user believed the message had gone. It now returns a result the input bar acts
  on — restoring the text and showing an error.

## Optimistic sending (added with the offline work)

`ChatCubit` now paints the bubble before the server has seen it:

- the bubble appears immediately marked `pending`, carrying a generated
  `clientId`;
- that `clientId` goes out with the socket emit;
- the server's echo **replaces** the optimistic bubble — both when it echoes
  `client_id` back and, via the content fallback, when it doesn't (an API build
  that predates the echo would otherwise show every sent message twice);
- another user's identical message is never mistaken for our pending one;
- a send that can't reach a live socket is marked `failed`, as is one that is
  never acknowledged before `ChatCubit.pendingTimeout`;
- `retryMessage` re-sends without the user retyping, `discardMessage` drops it;
- a `message_status` event never upgrades a message the server has not seen;
- media sends show the local file while uploading and leave a retryable bubble
  when the upload fails.

### Gotchas for this group

- `ChatCubit.pendingTimeout` is `@visibleForTesting` mutable. Shorten it for the
  timeout test and restore it in `addTearDown` — the default is 20 seconds.
- `_FakeChatSocketService` owns its own `onMessage` controller, because the real
  ones are private to `ChatSocketService`. `emitMessage` is how a test plays the
  gateway.
- `SharedPreferences.setMockInitialValues` must include a `userId`: the
  optimistic bubble's sender is built from stored preferences, and the
  content-matching fallback only considers messages sent by *us*.
- `OfflineCache.resetInstanceForTest()` in `setUp` — the cubit caches every
  loaded conversation, and the cache's in-memory mirror is process-wide.

### Regression locked in

`_markFailed` clears the pending timeout but **not** the outbound payload. An
earlier version dropped both, so "retry" on a failed message had nothing left to
send and silently did nothing.

## `editing`

The composer's edit mode lives in `ChatLoaded.editingMessage` rather than in the
input bar, because "Edit" is tapped in the long-press sheet — nowhere near the
composer.

- `startEditing` opens it; only text qualifies (replacing an image would be a
  different image, which is a new message)
- the new text is on screen before the server confirms it, and the composer
  closes at submit rather than at the response
- a **failed** save puts the original message back — including clearing the
  optimistic `editedAt`, so a message that had never been edited doesn't keep
  the "edited" marker a lost edit gave it
- unchanged text just closes the composer without a request
- a broadcast edit changes the text and `editedAt` **only**. The payload is
  serialized for the conversation as a whole, so its `status` is not this
  viewer's read state — applying it wholesale would knock the sender's own
  message back to a single check

## `reactions`

- optimistic: the chip appears before the request resolves, attributed to the
  signed-in user
- one reaction per person — a different emoji replaces the previous one, the
  same emoji again takes it back. Both rules match the server's, so the
  optimistic result and the broadcast that follows agree
- other people's reactions survive changes to yours
- a failed request rolls back to the previous list
- a still-sending message can't be reacted to: there is nothing on the server
  to attach the reaction to yet, and no request is made
- a broadcast replaces the **whole** list rather than merging — two people
  reacting at once would otherwise leave each client applying its own change to
  a list that had already moved on

## `remote deletion`

The `message_deleted` broadcast reaches the deleter too (via their personal
room), on top of the optimistic update they already applied, so the handler has
to be idempotent. It also closes the composer when it was editing the message
that just went — otherwise the user could save an edit to something that no
longer exists.
