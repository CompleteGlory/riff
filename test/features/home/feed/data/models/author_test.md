# `author_test.dart`

Covers `Author.followStatus` and the two getters that read it.

## The bug

A reel by someone you already follow showed a **Follow** button. Two halves,
both wrong:

- the reels API returned no follow information at all — its author JSON was
  `id`, `full_name`, `username`, `profile_image_url` and nothing else;
- with nothing to read, `reel_item.dart` declared `bool _isFollowing = false`
  and only ever set it when the viewer tapped Follow, so every reel started as
  "not following" whatever the truth was.

The API now sends `follow_status`, and this is the client half: parsing it,
and answering the two questions the UI actually asks.

## Why getters rather than string comparisons

`following` and `pending` differ in what the button *says* but agree that
offering "Follow" is wrong — a pending request must not be sent twice. Two
named getters keep that distinction in one place instead of spreading
`== 'following' || == 'pending'` across the widgets.

## What it covers

- the field parses, and is null when the payload omits it
- `isFollowedByViewer` is true for `following` **and** `pending`
- it is false for `not_following`, for a missing status, and for a value it
  does not recognise
- `hasPendingFollowRequest` separates the two, which is what selects
  "Requested" over a hidden button
- a JSON round trip preserves it

## Gotchas

- **A missing status must read as "not following", not as "following".** Reels
  are written to the offline cache, so a payload cached before this shipped has
  no `follow_status`. Hiding the button on that absence would leave a viewer
  unable to follow anyone from a cached reel.
- Only the reels endpoint sends this today, which is why the field is nullable
  rather than required.
