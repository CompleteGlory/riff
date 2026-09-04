# `media_source_sheet_test.dart`

Covers `MediaSourceSheet` — the "Camera / Photo / Video" chooser shared by
post creation, post editing and chat.

## Why it exists

Posts and chat each had their own bottom sheet, with their own paddings and
icons. Chat's was worse than duplicated: its labels were **hardcoded English**
in an app that localizes everything, and it offered **no camera at all**, so
sending a photo of what was in front of you meant leaving Riff, opening the
system camera, coming back, and finding the shot in the gallery.

## What it covers

- **order** — camera first, then photo library, then video library. The camera
  leads because it is the option that was missing; the point of the sheet is
  that capturing is now as reachable as browsing
- each row returns its own `MediaSource`
- `allowVideo: false` (a group photo) hides the video row *and* changes the
  camera label to promise only a photo, rather than offering video and
  rejecting it afterwards
- **every row is at least 48dp tall** — the Android floor, which also clears
  the 44pt iOS one
- dismissing without choosing completes with null, so a caller that awaits the
  sheet cannot hang

## Gotchas

- `MediaSourceSheet.show` returns a future that only completes when the route
  pops, so a test that taps a row must await it *after* pumping, not before.
- The dismissal test pops the navigator directly rather than tapping the
  scrim: the scrim's hit area depends on sheet height and makes the test about
  layout instead of about the contract.
