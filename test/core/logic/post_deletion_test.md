# `post_deletion_test.dart`

Covers `applyPostDeletion` — the pure function every cubit holding posts runs
when `PostEvents.deletions` fires.

## What it covers

- the deleted post is dropped from the list;
- a **share** of the deleted post is *not* dropped — it stays, loses its quoted
  post, and gains `originalPostDeleted: true` so the UI can render "post
  unavailable" instead of an empty share;
- both happen in a single pass when the original and one of its shares are in
  the same list;
- the **same list instance** comes back when nothing referenced the deleted
  post. Callers (`FeedCubit`, `ProfileCubit`, `ReelsCubit`, `SearchCubit`,
  `UserProfileCubit`) use `identical()` to decide whether to emit a new state
  and rewrite the offline cache, so this is behaviour, not an optimisation;
- the input list is never mutated.

## Mocked

Nothing — the function takes and returns plain `Post` lists.

## Gotchas

`Post` has no value equality, so assertions go through `id` and the individual
fields rather than comparing posts directly.
