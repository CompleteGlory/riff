# `post_cubit_test.dart`

## What it covers

`PostCubit.toggleLike` — that the like lands on screen before any network work,
and that repeat taps compute from what the user is actually looking at.

- `onOptimisticUpdate` fires **before** the repo is called.
- A server rejection calls `onRevert`.
- A second toggle sends `unlike`, not a second `like`.
- With no state passed, it still falls back to the values on the `Post`.

## What was slow (and it wasn't the network)

The cubit was always optimistic. The delay was in the caller: `PostItem`
`await`ed the whole heart-burst animation *before* calling `toggleLike` —
400 ms forward, 200 ms hold, 400 ms reverse — so the icon and the count sat
frozen for a full second on every like. The burst now plays alongside the state
change instead of gating it.

## Why the caller passes its own state

`toggleLike` derived the current state from `post.isLiked` / `post.likesCount`.
That model is the server's answer from when the feed loaded, and **nothing ever
writes back to it** — `PostItem` keeps its own `isLiked` / `likeCount` in State.
So a second tap recomputed `!post.isLiked`, got the same value it got the first
time, and sent another `like` instead of an `unlike`.

`currentIsLiked` / `currentLikeCount` let the caller pass what's on screen. They
default to the model, so `reel_item.dart` — which already worked around this by
constructing a synthetic `Post` carrying its local state — keeps working
unchanged.

This mattered more after the timing fix: a button that responds instantly is one
users tap twice.

## Testing gotcha

The "before the request" test stubs `likePost` with a `Completer` that **never
completes**. If the optimistic callback ever moved behind the network call, the
test would hang rather than fail — so the assertions run synchronously after an
un-awaited `toggleLike`, and the completer is resolved at the end to let the
future finish cleanly.

## What's mocked

`LikeRepo` and `FeedRepo` — mockito mocks (`@GenerateMocks`).
