# `user_search_cubit_test.dart`

Covers `UserSearchCubit` — searching for someone to start a chat with or add
to a group.

## Why it exists

`chats_list_screen` and `create_group_screen` each did this themselves: their
own `Timer`, their own results list and loading flag in `State`, and their own
`getIt<SearchRepo>()` call. That is the same business logic written twice in
two widgets, and **the two copies had already drifted** — only one debounced,
so the group screen fired a request per keystroke.

## What it covers

- typing several characters sends **one** request, not one per keystroke
- an empty or whitespace query clears immediately and sends nothing
- **a slow response for an older query cannot overwrite a newer one** — type
  "ali" then "alice" and the stale answer must lose
- a failed search shows no results rather than an error, because the user is
  mid-word and the next keystroke retries
- "nothing typed yet" is distinguishable from "searched and found nobody"
- `clear()` cancels a pending search, and `close()` cancels the timer

## Gotchas

- **The debounce is not a presentation detail.** It decides how many requests
  the app makes and has to be cancelled on close, which is why it lives on the
  cubit rather than in a widget's `State`.
- The stale-response guard is an epoch counter, the same shape used in
  `NotificationsCubit` and `ConnectivityService`. Three places now, so it is
  worth recognising: any async result applied to shared state needs to check
  that it has not been superseded.
- The cubit is registered with `registerFactory`, not as a singleton — two
  search fields sharing one instance would clear each other. Each screen holds
  its own on the `State` and hands it down with `BlocProvider.value`. Creating
  it inside `build` instead puts the provider *below* the State element, and a
  State method calling `context.read` then throws on the first keystroke.
