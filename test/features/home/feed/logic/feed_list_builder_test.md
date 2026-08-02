# `feed_list_builder_test.dart`

## What it covers

`buildFeedItems` — the ordering rules for the mixed feed list (posts + the
trending card + ads).

The rule that matters: **a post shown as trending is never also shown as an
ordinary row.**

## What broke

The trending post is just a feed post that happens to be trending, so
`GET /posts` returns it like any other. `_buildMixedList` inserted the trending
card after the second post but never removed the same post from the list, so the
feed rendered it twice, a few rows apart — once normally, once in the yellow
Trending card.

## The subtle part

Filtering the duplicate out shortens the list, and the card is only ever
inserted at index 1. A feed of two posts where one *is* the trending post drops
to a single post, the loop never reaches `i == 1`, and the trending card would
disappear entirely — trading a duplicate for a disappearance. `buildFeedItems`
tracks whether it inserted the slot and appends it if not; three tests cover
that (two posts, one post, and the ad interaction, since the same shortening
also skips the `adEvery` boundary).

## Why it's a separate file

`_buildMixedList` was a private method on a private `State` class, reachable
only through a widget test that would need `FeedCubit`, `HomeCubit`, `AdRepo`
and the network. Extracting the pure ordering rules follows the same approach as
[conversation_dedupe_test.md](../../chat/logic/cubit/conversation_dedupe_test.md)
— the widget keeps the wiring, the logic gets tested on its own.

## What's mocked

Nothing. `buildFeedItems` is pure; the tests build bare `Post`/`Ad` values.
