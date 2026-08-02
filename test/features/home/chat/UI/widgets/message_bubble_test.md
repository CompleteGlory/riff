# `message_bubble_test.dart`

## What it covers

Opening a chat image fullscreen, the same way post images open.

- tapping a sent image pushes `FullScreenImage` with the remote URL;
- tapping an image that is **still uploading** opens it straight off disk
  (`isLocalFile`), so the user doesn't have to wait for the upload to finish;
- a **failed** image doesn't open the viewer — the tap belongs to the retry
  handler on the whole bubble;
- the viewer closes back to the chat, and shows no gallery chrome (page dots,
  "1 / 3" counter) for a single image.

## What's mocked

Nothing. `Image.network` fails in tests and renders the widget's `errorBuilder`,
which is enough to lay the bubble out and tap it.

## Gotchas

These three cost real time, and none of them are obvious from the failure:

- **`pump_app.dart`'s helper can't be used here.** It ends in `pumpAndSettle`,
  and a *pending* bubble carries a `CircularProgressIndicator` that never
  settles — the test times out instead of failing. This file pumps a bounded
  duration instead.
- **The default 800x600 test surface is too small.** An image bubble is
  `0.65.sw` wide and unbounded in height; it overflows, its centre lands
  off-screen, and `tap()` misses the widget it just *found* — reported as a
  hit-test warning, then a confusing assertion failure. The viewport is set to
  390x844.
- **`Image.file` never resolves under the test binding's fake clock**, even with
  a real file on disk and `runAsync`. The bubble stays zero-height, so a
  still-uploading image can't be tapped for real. That one case invokes the
  keyed `GestureDetector`'s callback directly — `MessageBubble.imageTapKey`
  exists for exactly this.

## Regression locked in

The failed-send case asserts the image's own tap handler is `null`, not just
that the viewer didn't open. If the viewer were wired up unconditionally it
would swallow the tap and leave a failed message with no way to resend it.
