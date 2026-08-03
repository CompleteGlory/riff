# `message_reactions_test.dart`

Widget tests for the two things `MessageBubble` grew alongside reactions and
editing: the row of reaction chips, and the "edited" marker.

Separate from `message_bubble_test.dart` on purpose — that file is about the
image bubble and its fullscreen viewer, and its `pumpBubble` helper is shaped
around an image's layout quirks (unbounded height, a pending
`CircularProgressIndicator` that never settles). Text bubbles need none of
that, so this file has its own simpler helper that can use `pumpAndSettle`.

## What it covers

### Reaction chips

- no reactions → nothing drawn
- one chip per distinct emoji
- the same emoji from several people collapses into **one** chip with a count,
  rather than one chip each — a group chat would otherwise fill the screen
- a lone reaction shows no `1` beside it
- tapping a chip reports that emoji back through `onReactionTap`, which is what
  toggles it

### Edited marker

- an unedited message carries no marker
- `editedAt` being present is the signal, not a comparison against `createdAt`
  — a message saved twice for unrelated reasons must not get labelled as
  something the sender rewrote
- a deleted message shows neither the marker nor the original text: it renders
  as a different widget entirely, and the marker would be describing text
  nobody can see

## Mocks

None. `MessageBubble` takes the message, `myId` and the tap callback directly;
the test collects tapped emoji into a list.

## Gotchas

- The viewport is set to a phone shape (390×844) for the same reason as
  `message_bubble_test.dart` — the default 800×600 test surface can push a
  bubble's centre off-screen, so `tap()` misses the widget it just found.
- Assertions use `S.current`, not a hardcoded string, so the test doesn't have
  to be edited when the copy changes and would catch a missing ARB key.
