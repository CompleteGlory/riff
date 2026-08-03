# `post_actions_test.dart`

## What it covers

The like row's two tap targets.

- tapping the **count** opens the likers list and does **not** add a like;
- tapping the **heart** likes and does not open the list;
- the count is inert at zero likes (nothing to show) — the whole button
  toggles the like, as before;
- a caller that doesn't pass `onLikeCountTap` keeps the original
  one-button-does-everything behaviour;
- comment and share are unaffected, and the view count is still non-interactive.

## What's mocked

Nothing. Counters stand in for the callbacks.

## Gotchas

- The heart is found via `find.byType(SvgPicture).first` — the row has four
  SVGs (heart, chat, eye, share) and the heart is first. Tapping by computed
  offset instead was fragile and, worse, could land on the count.
- The action labels are plain numbers, so `find.text('12')` is how the count is
  located. Keep the fixture counts distinct from each other.

## Regression locked in

The heart and its number used to be a single `GestureDetector`, so there was no
way to see *who* liked a post without liking it yourself. The first two tests
pin the split: each target does one thing, and neither does the other's.
