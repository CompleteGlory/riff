# `comment_author_fallback_test.dart`

## What it covers

`commentWithAuthorFallback` — the merge that runs when a posted comment comes
back from the server.

- A response with **no** author keeps the optimistic one, so the avatar stays.
- Everything else on the response is kept (most importantly the real `id`; the
  optimistic one is a negative placeholder the likes map is keyed off).
- A response **with** an author wins — it carries the real display name rather
  than the "You" placeholder.

## What broke

The sheet inserts an optimistic comment built from the cached profile image and
a "You" label, then swaps it for whatever `POST .../comments` returns. That
endpoint returned the freshly inserted row without loading its `user` relation
— unlike `GET .../comments`, which has always returned it with the author
attached.

So the swap replaced a comment that had an author with one that had none: the
user's own comment lost its picture *and* its name the instant it posted, and
only got them back on a reload (which reads the list endpoint).

## Two halves

The API is fixed too — `CreateComment` now reloads through
`CommentRepository.findWithAuthor`, so the response carries the author. See
[create-comment.spec.md](/Users/magd/apis/riff/src/modules/comments/use-cases/create-comment.spec.md).

This client-side fallback is the belt-and-braces half. It fixes the app before
that deploy lands, covers older builds still in the wild, and stops any future
response from downgrading what is already on screen.

## What's mocked

Nothing. `commentWithAuthorFallback` is a pure top-level function, which is why
it lives outside `_CommentsSheetState` — the state class is private, so logic
inside it is only reachable through a widget test that would need GetIt, a
`CommentCubit` and the network.
