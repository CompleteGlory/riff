# `like_repo_test.dart`

## What it covers

`LikeRepo.getPostLikers` — the request behind the "who liked this" list.

- hits `/api/posts/{id}/likes`;
- parses users **and their follow status**;
- an empty list is a success, not a failure;
- a network failure and an unexpected body shape both come back as
  `ApiResult.failure` rather than throwing or half-parsing.

## What's mocked

`ApiService` and `Dio` (`@GenerateMocks`). `getPostLikers` only uses `Dio` —
`LikeRepo` goes through `ApiService` for like/unlike but straight to `Dio` here,
matching how `FollowRepo` fetches its lists.

## Why `FollowUser`, not a like-specific model

The endpoint returns the same rows as `/users/:id/followers` on purpose, so the
list reuses `FollowUser`, the same screen and the same follow buttons. The
`follow_status` assertion is the load-bearing one: it comes down with the list
so each row's follow button doesn't need a request of its own.

## Regression locked in

The unexpected-body-shape case. The screen renders whatever the repo returns, so
a body it can't read has to fail cleanly at the boundary rather than reach the
UI as a half-parsed list.
