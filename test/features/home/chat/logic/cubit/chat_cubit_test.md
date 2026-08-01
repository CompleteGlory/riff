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
