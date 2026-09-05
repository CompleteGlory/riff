# `linkified_text_test.dart`

## What it covers

Making links in user-written text pressable, without breaking the two gestures
that were already there.

| Case | Expected |
| --- | --- |
| text with no links | a plain `Text`, no spans, no recognizers |
| tap on a link | `onLinkTap` receives the URL |
| `www.example.com` | displayed as typed, **opened** as `https://…` |
| words around a link | preserved as plain spans, in order |
| tap away from a link | the enclosing card's `onTap` still fires |
| text replaced | the old recognizer is gone, the new one works |

## Why the gesture cases matter most

A post card is wrapped in a `GestureDetector` that opens the post, and a
`TapGestureRecognizer` on a span competes with it in the same arena. Getting
this wrong in either direction is a real regression: a link that does nothing,
or a post body that can no longer be tapped to open the post. `a tap away from
the link still reaches the card` pins the second.

Long-press-to-copy is unaffected and is covered where it lives, in
`post_content.dart`'s own widget: these recognizers claim taps only.

## Why disposal is tested

`TapGestureRecognizer` holds an arena entry and leaks if it outlives its span.
That is why this is a `StatefulWidget` at all — a stateless version would leak
one recognizer per link **per rebuild**, which in a scrolling feed is
continuous. `releases its recognizers when the text changes` is the case that
would catch a rebuild that forgot to release the previous set.

## What's mocked

`onLinkTap`, which defaults to `url_launcher`. Injecting it follows the
pattern the login tests established for anything plugin-backed — the widget is
tested without a platform channel, and the assertion is on the URL that would
be opened.

## Gotcha

The tests fire the recognizer directly rather than tapping at a coordinate.
Hit-testing an individual `TextSpan` means laying out the paragraph and
computing a glyph offset, which makes the test about text metrics — it breaks
when the font or the test viewport changes, not when the behaviour does.
