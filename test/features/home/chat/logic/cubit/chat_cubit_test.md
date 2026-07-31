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
- **Fire-and-forget sends.** `sendText` returned `void` and emitted into
  whatever socket happened to be there. The composer cleared either way, so the
  user believed the message had gone. It now returns a result the input bar acts
  on — restoring the text and showing an error.
