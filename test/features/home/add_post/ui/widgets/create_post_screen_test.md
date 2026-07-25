# create_post_screen_test

Regression tests for the **"blank screen after posting"** bug and the
`CreatePostScreen.popOnSubmit` behavior.

## What it covers

`CreatePostScreen` is presented two different ways, and submitting must navigate
differently in each:

| Presentation | `popOnSubmit` | Expected on submit |
| --- | --- | --- |
| The **Create Post tab** inside `HomeLayout` (`screens[2]`, not its own route) | `false` | **Must NOT pop** — popping would remove `HomeLayout` itself → blank screen. `HomeLayout` switches to the feed tab on upload start instead. |
| **Pushed** as its own route by the share flows (IG/TikTok link, shared media) | `true` | **Pops** to reveal what's underneath (the feed). |

Tests:
1. `popOnSubmit=false` → after entering content and tapping **Post**, the screen
   stays (no pop), and the upload still fires (`createPost` called once).
2. `popOnSubmit=true` → tapping **Post** pops back to the route below.
3. Empty content → `_handlePost` shows a snackbar and returns; no pop, and
   `createPost` is never called.

## What's mocked / how

- **`CreatePostRepo`** — mocked via `@GenerateMocks([CreatePostRepo])`
  (generated into `create_post_screen_test.mocks.dart`). A **real**
  `CreatePostCubit(mockRepo)` is used, provided via `BlocProvider.value`,
  matching the repo's "mock the repo, use the real cubit" convention.
- The mocked `createPost(...)` returns a **never-completing** future
  (`Completer<ApiResult<Post>>().future`). The pop decision in `_handlePost`
  runs synchronously right after `createPost` is invoked (it is not awaited), so
  the upload's eventual outcome is irrelevant — hanging it keeps the test focused
  on navigation and avoids constructing a full `Post`/error model.

## Gotchas learned here

- **`CreatePostScreen` is pushed on top of a placeholder "BELOW" route** so that
  `Navigator.canPop(context)` is `true`. If it were the `home:` of the test
  `MaterialApp`, `canPop` would be `false` and even `popOnSubmit=true` couldn't
  pop, so the two cases wouldn't be distinguishable.
- **Use `pumpAndSettle()` after tapping Post**, not a couple of bare `pump()`s —
  the `Navigator.pop` triggers a ~300ms route transition; without settling it,
  `CreatePostScreen` is still animating out and `findsNothing` fails.
- Content is **required**; enter text before tapping Post or `_handlePost`
  early-returns with a snackbar and never submits.
