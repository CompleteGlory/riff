# `reels_merge_test.dart`

## What it covers

`mergeReels` — what the reels screen does with a freshly delivered list.

- a **corrected count on the same reels is accepted** (the reported bug);
- a count-only change does **not** resync the video controllers;
- a delivery that changes nothing is ignored, so the screen doesn't churn;
- added or reordered reels do resync;
- the reel the user tapped to get here stays pinned at index 0 and is never
  also listed further down;
- comment counts and the viewer's own like toggle count as changes too.

## What's mocked

Nothing — `mergeReels` is pure. That is the point of extracting it: the rules
can be tested without booting a screen full of `VideoPlayerController`s, the
same reason `feed_list_builder.dart` exists.

## Gotcha

The fixtures use reels with a **nested-free** `Post`, but the ids must differ
per case — several assertions are about ordering, and identical ids would make
them pass for the wrong reason.

## Regression locked in

The screen used to accept a delivery only when the list **length** changed:

```dart
if (merged.length == _reels.length) return; // nothing new
```

That silently discarded every correction to a reel already on screen. It was
harmless while the first delivery was always the live one — but once reels were
cached for offline use, the cached list painted first, the live list arrived
with the same ten items, the lengths matched, and the fresh data was thrown
away. A reel kept showing a stale like count while its own post screen showed
the correct one.

Reverting `changed` to the length comparison fails 4 of these 9 tests.
