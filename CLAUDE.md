# Riff – Project Context for Claude

## Overview

Riff is a music-social app with two separate codebases:

| Repo | Path | Stack |
|------|------|-------|
| Flutter app | `/Users/magd/apps/flutter/riff` | Flutter + BLoC/Cubit + GetIt |
| NestJS API | `/Users/magd/apis/riff` | NestJS + TypeORM + PostgreSQL |

Both folders are mounted and accessible. **Always read the relevant files before editing.**

---

## Before Starting Any Feature

1. **Ask for the files** — read the existing screens, cubits, repos, and API controllers that the feature will touch before writing a single line.
2. **Match the architecture** — follow the exact patterns already in the codebase (BLoC/Cubit, GetIt, Dio, repository layer).
3. **Localize everything** — no hardcoded strings anywhere in Flutter UI (see Localization section below).
4. **Handle both sides** — Flutter UI + API endpoint + DB migration if needed.

---

## Flutter Architecture

### Folder structure per feature
```
lib/features/<feature>/
  UI/              # Screens and widgets
  data/
    models/        # Dart model classes (fromJson/toJson)
    repos/         # Repository classes — wrap Dio calls
  logic/
    cubit/         # Cubit + State files
```

### Core infrastructure
```
lib/core/
  di/dependency_injection.dart   # GetIt setup — register everything here
  cache/
    offline_cache.dart           # last-known-good JSON store, scoped per user
    cache_keys.dart              # bucket names + how much of each is kept
  logic/
    reconnect_refresh.dart       # cubit mixin: re-fetch when the connection returns
  networks/
    api_constants.dart           # ALL endpoint strings go here
    dio_factory.dart             # Dio instance with auth interceptor
    connectivity_service.dart    # online/offline signal, derived from real requests
  helpers/
    shared_pref_helper.dart      # SharedPreferences wrapper
    constants.dart               # SharedPrefKeys and other constants
  themes/
    colors/color_manager.dart
    text_styles/text_styles.dart
  routing/routes.dart            # Named route strings
  utils/media_url.dart           # MediaUrl.resolve() — always use this for image URLs
```

### Key patterns

**State management:** Flutter BLoC Cubit pattern everywhere. Each feature has `XxxCubit extends Cubit<XxxState>`.

**DI:** GetIt singleton via `getIt<T>()`. Register new repos/cubits in `lib/core/di/dependency_injection.dart`.

**HTTP:** Dio instance from GetIt. All endpoints in `ApiConstants`. Repos call `_dio.get/post/patch/delete`.

**Navigation:** Named routes via `Routes` constants + `Navigator.pushNamed` or `Navigator.push` with `MaterialPageRoute`.

**Sizing:** `flutter_screenutil` — always use `.w`, `.h`, `.r` for width, height, radius.

**Images:** Always use `CachedNetworkImage` / `CachedNetworkImageProvider`. Always resolve URLs via `MediaUrl.resolve(url)`.

**User lists:** `FollowListScreen` is the one screen for "a list of people" — followers, following, and who liked a post (`FollowListScreen.postLikers`). All three endpoints return the same user-with-`follow_status` rows, so they share the model (`FollowUser`), the rows, the search box and the follow buttons. Add a `FollowListType` variant rather than a new screen.

**Fullscreen images:** `FullScreenImage` (`lib/features/home/feed/Ui/widgets/post/fullscsreen_image.dart`) is the one viewer — pinch-to-zoom, swipeable gallery, page dots when there's more than one. Used by post media, profile media and chat images. `FullScreenImage.single(imageUrl:)` for one URL, `FullScreenImage.localFile(path:)` for a file not uploaded yet (a chat image mid-send). Local vs remote is an explicit constructor choice, never sniffed from the string: a leading `/` means a local path *and* a legacy relative URL.

**API base URL:** `https://riff-production-08f7.up.railway.app` (Railway deployment)

---

## Offline Experience

The app assumes the connection will fail and is built to stay usable when it
does. Three pieces:

### 1. Knowing you're offline — `ConnectivityService`

No connectivity plugin. The status is derived from what real requests actually
do, via the Dio interceptor:

- any response → **online** (the server answered, whatever the status code);
- a *transport* failure (connection error, timeout, socket error) → **offline**;
- an HTTP failure (401, 404, 500) → still **online**.

While offline it re-probes the API host on a backoff (3s → 30s) so recovery is
noticed without the user doing anything, and `HomeLayout` probes on resume.
`ConnectivityService.onStatusChanged` emits **transitions only**.

`ApiErrorHandler` marks transport failures with `statusCode: kOfflineStatusCode`
(`-1`); use `error.isOffline` rather than sniffing the message text for the word
"connection" — that never worked in Arabic.

### 2. Showing something anyway — `OfflineCache`

JSON files under `offline_cache/<userId>/`, one per bucket. Partitioned by user,
wiped by the sign-out hook, never throws — a failed read or write degrades to
"no cache".

| Bucket | Kept | Written by |
|--------|------|-----------|
| `feedPosts` | 10 | `FeedCubit` (first page only) |
| `conversations` / `conversationRequests` | 10 | `ChatsListCubit` |
| `reels` | 10 | `ReelsCubit` (first page only) |
| `myProfile` | 1 | `HomeCubit` |
| `myPosts` | 10 | `ProfileCubit` (own profile only) |
| `discoverPosts` | 30 | `SearchCubit` (unfiltered discover only) |
| `messages_<conversationId>` | 30 | `ChatCubit`, per conversation |

Deleting a post prunes every bucket that could hold it — see `PostEvents` and
`applyPostDeletion` in `lib/core/logic/`. The prune reads the bucket and writes
it back rather than rewriting it from what is on screen: `myPosts` holds only
the signed-in user's posts while `ProfileCubit` may be showing someone else's,
and `feedPosts`/`reels` hold the first page while the cubit may hold several.

**Anything handed to the cache must be genuinely JSON-encodable.** `OfflineCache`
normalises on write (encode, then mirror the re-decoded result) so this can't
bite again, but be aware that `Post.toJson()` — and any other json_serializable
model without `explicitToJson: true` — returns nested *objects*, not maps. It is
only safe to `json.encode`, never to read back field-by-field.

The pattern in every cubit is the same:

1. nothing on screen → read the cache and emit it as a normal `success`, with an
   `isShowingCached` flag for the UI, instead of emitting `loading`;
2. request succeeds → **replace** (don't append to) the cached list, clear the
   flag, cache the fresh first page;
3. request fails → if anything is on screen, leave it there; only emit a failure
   when there is genuinely nothing to show.

Cubits that can show cached content mix in `ReconnectRefresh` and re-fetch
themselves when connectivity returns.

UI: `OfflineBanner` wraps the whole navigator in `RiffMaterialApp.builder`
(a persistent bar plus a brief "back online" confirmation);
`OfflineCachedNotice` is the per-screen "this list is a snapshot" strip;
`OfflineEmptyState` is "offline, and nothing was saved".

### 3. Optimistic message sending

`ChatMessage` carries `clientId`, `delivery` (`complete` | `pending` | `failed`)
and `localMediaPath`. `ChatCubit.sendText`/`sendMedia` put the bubble on screen
immediately, dimmed, then either firm it up or mark it failed:

- the client generates a `clientId` and sends it with the message;
- the gateway echoes it back **only to the sender** (`client_id` on the socket
  payload; on the HTTP response for uploads) — recipients must never see it or
  they'd match it against their own bubbles;
- `ChatCubit._indexOfOptimisticMatch` replaces the optimistic bubble with the
  server's copy, falling back to sender+type+content matching so the app still
  reconciles against an API build without the echo;
- an unacknowledged send fails after `ChatCubit.pendingTimeout` (20s) — a socket
  `emit` succeeding only means bytes left the device;
- a failed bubble is tappable (retry) and long-pressable (retry / discard);
  `_markFailed` deliberately keeps the outbound payload so retry has something
  to send.

### 4. Not getting signed out

See `SessionManager`. A refresh now retries transient failures on a backoff,
needs **two** confirmed rejections before ending the session, never believes a
rejection that arrives while offline, and retries with the newer token when
storage rotated it mid-flight.

---

## Localization

**All UI strings must be localized. No exceptions.**

### How it works
- ARB files: `lib/l10n/intl_en.arb` (English) and `lib/l10n/intl_ar.arb` (Arabic)
- Generated class: `lib/generated/l10n.dart` — `S` class, accessed via `S.of(context).keyName`
- Regenerate after editing ARB files with:

  ```bash
  dart run intl_utils:generate
  ```

  **Not** `flutter gen-l10n`. This project generates the `S` class with `intl_utils` (configured
  under `flutter_intl:` in `pubspec.yaml`, output to `lib/generated/`), and `flutter:
  generate: true` is deliberately not set — `flutter gen-l10n` just fails with "Attempted to
  generate localizations code without having the flutter: generate flag turned on."

### Adding a new string
1. Add the key + English value to `lib/l10n/intl_en.arb`
2. Add the same key + Arabic translation to `lib/l10n/intl_ar.arb`
3. Use `S.of(context).yourKey` in the widget

### ARB format
```json
// intl_en.arb
{
  "yourKey": "Your English text",
  "@yourKey": {}
}
```

### Example usage in widget
```dart
// ✅ Correct
Text(S.of(context).groupNameHint)

// ❌ Never do this
Text('Group name')
```

### Existing keys (sample)
`newGroupTitle`, `createGroupBtn`, `groupNameHint`, `groupDescriptionHint`, `searchUsersHint`, `groupNameRequired`, `groupMemberRequired`, `groupCreationError`, `groupDetailsTitle`, `groupMembersSection`, `groupAdminBadge`, `groupDescriptionLabel`, `groupNoDescription`, `saveChangesBtn`

---

## API Architecture (NestJS)

### Structure
```
src/
  modules/<feature>/
    *.controller.ts       # HTTP endpoints
    *.gateway.ts          # WebSocket gateway (chat)
    entities/             # TypeORM entities
    repositories/         # DB query layer
    services/             # Business logic / external services
    use-cases/            # Single-responsibility use-case classes
  infrastructure/
    typeorm/
      migrations/         # All DB migrations — numbered timestamps
```

### Adding a new endpoint
1. Add method to `*.controller.ts` with `@Get/@Post/@Patch/@Delete` decorator
2. Add business logic in a use-case file or service
3. Add repo method in the repository if DB query needed
4. Add migration if schema changes needed
5. Add constant to Flutter's `ApiConstants`

### Auth
All endpoints are JWT-protected via global `JwtAuthGuard`. The user id comes from `req.user.id`.

### WebSocket (Chat)
`chat.gateway.ts` — Socket.IO gateway. Rooms are conversation IDs. Sender gets echo via personal user room.

---

## Database — PostgreSQL on Railway

- **Host:** Railway PostgreSQL (production)
- **Migrations table:** `migrations` (NOT `typeorm_migrations`)
- **Run migrations:** `npm run migration:deploy` (runs `node dist/...` compiled JS)
- **When schema diverges:** apply SQL directly via `railway run node -e "...ALTER TABLE..."`
- **Migration filename format:** `<timestamp>-<Description>.ts` e.g. `1782069756713-AddFcmTokenToUsers.ts`

### Creating a migration
```bash
npm run migration:generate -- src/infrastructure/typeorm/migrations/MyMigration
npm run build
npm run migration:deploy
```

---

## File Storage — Cloudinary

All media is uploaded to Cloudinary. Three separate service classes handle this:

| Service | Folder | Used for |
|---------|--------|---------|
| `PostMediaService` | `riff/posts` | Post images/videos |
| `ChatMediaService.save()` | `riff/chat` | Chat media messages |
| `ChatMediaService.saveGroupPhoto()` | `riff/groups` | Group conversation photos |
| `AdMediaService` | `riff/ads` | Commercial ad media |
| `FileUploadService` (users) | `riff/profiles` | Profile pictures |

**Env vars required:**
```
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
```

Upload pattern (NestJS):
```typescript
cloudinary.uploader.upload_stream(
  { folder: 'riff/<folder>', resource_type: 'auto' | 'image' | 'video' },
  (error, result) => { ... }
).end(file.buffer);
```

On the Flutter side, always upload via `FormData` with `MultipartFile.fromFile(...)` then pass the returned URL to subsequent API calls.

---

## Push Notifications — Firebase FCM

- `fcm_token` column on `users` table
- `FcmService` (`src/modules/notifications/fcm.service.ts`) sends push via Firebase Admin SDK
- Token saved when user logs in or app resumes via `save-fcm-token` use-case
- `FIREBASE_SERVICE_ACCOUNT_JSON` env var required (JSON string of Firebase service account)

---

## Spotify Integration

- OAuth tokens stored on `users` table: `spotify_access_token`, `spotify_refresh_token`, `spotify_token_expires_at`
- `SpotifyService` handles connect/disconnect/refresh/now-playing
- `SPOTIFY_CLIENT_ID` and `SPOTIFY_CLIENT_SECRET` env vars required

---

## Chat System

### Flutter side
- `ChatSocketService` — Socket.IO wrapper, streams: `onMessage`, `onTyping`, `onRead`, `onMessageStatus`, `onPresence`, `onConversationDeleted`
- `ChatCubit` — manages a single open conversation's state
- `ChatsListCubit` — manages the conversations list + unread badge counts
- Media messages: `ChatRepo.uploadMedia()` → `POST /api/chat/conversations/:id/messages/upload`
- **Dedup guard in `ChatCubit.sendMedia()`** — socket broadcast can arrive before HTTP response; always check `msg.id` before prepending to list

### API side
- `ConversationRepository` — all DB operations for conversations + participants
- `MessageRepository` — messages CRUD
- `ChatGateway` — Socket.IO, rooms = conversation IDs, user personal rooms = `user:<id>`
- Group photo upload: `POST /api/chat/group/photo` → returns `{ url }`
- Group update: `PATCH /api/chat/conversations/:id/group` (admin only)

---

## Share Receiver (Receiving shares from other apps)

- Package: `receive_sharing_intent: ^1.8.1`
- `ShareReceiverService` singleton (`lib/features/social_share/services/share_receiver_service.dart`)
- `init()` is called in `HomeLayout.initState()` AND in `didChangeAppLifecycleState(resumed)` — the resumed call catches shares delivered while app was backgrounded
- Navigation uses `addPostFrameCallback` + `Future.delayed(300ms)` to avoid cold-start race condition
- Platform detection supports: `instagram`, `tiktok`, `spotify` (including `spotify:` URI scheme)

---

## Testing

Test dependencies: `mockito` (mocking, per the
[Flutter cookbook mocking guide](https://docs.flutter.dev/cookbook/testing/unit/mocking)),
`bloc_test` (Cubit/Bloc state-transition assertions), `integration_test` (end-to-end device tests).
Regenerate mocks with `dart run build_runner build --delete-conflicting-outputs` after changing
any `@GenerateMocks` target.

### Login module (reference implementation)

`lib/features/auth/login/` has full unit + widget + integration coverage and is the pattern to
copy for other features. Each test file has a co-located `.md` explaining what it covers, what's
mocked, and any timing/testability gotchas:

| Layer | Test | Doc |
| --- | --- | --- |
| Repo (API calls) | `test/features/auth/login/data/repos/login_repo_test.dart` | [login_repo_test.md](test/features/auth/login/data/repos/login_repo_test.md) |
| Cubit | `test/features/auth/login/logic/cubit/login_cubit_test.dart` | [login_cubit_test.md](test/features/auth/login/logic/cubit/login_cubit_test.md) |
| Widget — form fields | `test/features/auth/login/UI/widgets/login_form_fields_test.dart` | [login_form_fields_test.md](test/features/auth/login/UI/widgets/login_form_fields_test.md) |
| Widget — Google sign-in | `test/features/auth/login/UI/widgets/social_login_test.dart` | [social_login_test.md](test/features/auth/login/UI/widgets/social_login_test.md) |
| Widget — state → dialogs/nav | `test/features/auth/login/UI/widgets/login_bloc_listener_test.dart` | [login_bloc_listener_test.md](test/features/auth/login/UI/widgets/login_bloc_listener_test.md) |
| Widget — full screen | `test/features/auth/login/UI/login_screen_test.dart` | [login_screen_test.md](test/features/auth/login/UI/login_screen_test.md) |
| Integration (whole feature) | `integration_test/login_flow_test.dart` | [login_flow_test.md](integration_test/login_flow_test.md) |
| Shared helper | `test/helpers/pump_app.dart` | [pump_app.md](test/helpers/pump_app.md) |

Testability patterns established here, worth reusing elsewhere:

- Wrap any static/plugin-backed call (e.g. `google_sign_in`) behind a small injectable interface
  with a real-implementation default, instead of calling the static helper directly from a widget.
- Give any widget that triggers a singleton side effect (push notifications, analytics, etc.) an
  optional constructor callback defaulting to the real singleton call, so tests can no-op it.
- Don't declare a `Cubit<SomeFreezedUnion>` with the freezed type left generic and unspecified —
  it silently resolves to `dynamic` and breaks `bloc_test` state matchers even when behavior is
  correct.
- Don't declare a cubit's async emit methods as `void ... async` — widen to `Future<void> ...
  async`. It's a free, backward-compatible change (existing call sites that don't await it keep
  working) and it's the only way a test can sequence `await cubit.doThing()` before asserting.
- Any cubit method with a "recover from SharedPreferences if nothing's in memory" fallback path
  needs `SharedPreferences.setMockInitialValues({})` in every test that can reach it — even ones
  that don't otherwise care about persistence. Skipping it doesn't fail the test; the real
  platform-channel call just never resolves and the test (or the whole `flutter test` process)
  hangs instead of reporting a clean failure.
- When a cubit method calls a second repo after the first succeeds (e.g. auto-login after
  signup), stub *both* mocks in every test that exercises that path — even if a test only cares
  about the first call's timing. An unstubbed dependent mock throws inside the cubit, silently
  aborting it before the final state is ever emitted, which surfaces as a `pumpAndSettle() timed
  out` on an indeterminate loading spinner rather than an obviously-related error.
- Widget-test a form in the same scroll context production uses it in (e.g. wrap in
  `SingleChildScrollView` if the real screen does) — pumping a large form bare inside a `Scaffold`
  can overflow the default test viewport before any assertion runs.
- `OfflineCache` and `ConnectivityService` are process-wide singletons with
  in-memory state (a cache mirror, an offline verdict and a live backoff timer).
  Any test touching a cubit that caches or reports connectivity needs
  `OfflineCache.resetInstanceForTest()` / `ConnectivityService.resetInstanceForTest()`
  in `setUp` — otherwise data cached by one test is restored into the next, which
  is exactly how `chats_list_cubit_test` started failing when the cache landed.
- When combining `AppScopedCubit` with another `on Cubit` mixin that overrides
  `close()`, apply `AppScopedCubit` **last** so its no-op `close()` runs first.
  The other order lets a route-level close tear down the other mixin's resources
  while the singleton itself stays alive.
- Never call `pumpAndSettle()` after a transition onto a screen with a repeating `Timer.periodic`
  or a looping `AnimationController` (e.g. a countdown, a blinking cursor) — it never settles. Use
  a bounded `tester.pump(someDuration)` instead.

### Other auth features

The same repo/cubit/widget layering was applied to the rest of `lib/features/auth/`:

| Feature | Repo test | Cubit test | Widget tests |
| --- | --- | --- | --- |
| `forgot_password` | [forgot_password_repo_test.md](test/features/auth/forgot_password/data/repos/forgot_password_repo_test.md) | [forgot_password_cubit_test.md](test/features/auth/forgot_password/logic/cubit/forgot_password_cubit_test.md) | [forgot_password_form_field_test.md](test/features/auth/forgot_password/UI/widgets/forgot_password_form_field_test.md), [reset_password_form_fields_test.md](test/features/auth/forgot_password/UI/widgets/reset_password_form_fields_test.md), [forgot_password_bloc_listener_test.md](test/features/auth/forgot_password/UI/widgets/forgot_password_bloc_listener_test.md), [request_otp_bloc_listener_test.md](test/features/auth/forgot_password/UI/widgets/request_otp_bloc_listener_test.md), [reset_password_bloc_listener_test.md](test/features/auth/forgot_password/UI/widgets/reset_password_bloc_listener_test.md) |
| `signup` | [signup_repo_test.md](test/features/auth/signup/data/repos/signup_repo_test.md) | [signup_cubit_test.md](test/features/auth/signup/logic/cubit/signup_cubit_test.md) | [signup_form_fields_test.md](test/features/auth/signup/UI/widgets/signup_form_fields_test.md), [signup_bloc_listener_test.md](test/features/auth/signup/UI/widgets/signup_bloc_listener_test.md) |
| `new_user_onboarding` | [suggested_users_repo_test.md](test/features/auth/new_user_onboarding/data/repos/suggested_users_repo_test.md) | *(no cubit — screen calls the repo directly)* | *(not covered — see below)* |

### Session, navigation & notification routing

The cross-cutting auth/navigation layer has its own suite. Same convention — each
test file has a co-located `.md` explaining coverage, mocks and gotchas:

| Area | Test | Doc |
| --- | --- | --- |
| Push payload → destination (pure) | `test/core/services/notification_route_test.dart` | [notification_route_test.md](test/core/services/notification_route_test.md) |
| Token refresh, expiry, sign-out | `test/core/services/session_manager_test.dart` | [session_manager_test.md](test/core/services/session_manager_test.md) |
| Notification-tap navigation | `test/core/services/push_notification_service_test.dart` | [push_notification_service_test.md](test/core/services/push_notification_service_test.md) |
| Context-free navigation | `test/core/routing/navigation_service_test.dart` | [navigation_service_test.md](test/core/routing/navigation_service_test.md) |
| Route table + singleton providers | `test/core/routing/app_router_test.dart` | [app_router_test.md](test/core/routing/app_router_test.md) |
| App-lifetime cubit lifecycle | `test/core/logic/app_scoped_cubit_test.dart` | [app_scoped_cubit_test.md](test/core/logic/app_scoped_cubit_test.md) |
| Mark-all-read + singleton survival | `test/features/home/notifications/logic/cubit/notifications_cubit_test.dart` | [notifications_cubit_test.md](test/features/home/notifications/logic/cubit/notifications_cubit_test.md) |
| Chat socket lifecycle + send result | `test/features/home/chat/logic/cubit/chat_cubit_test.dart` | [chat_cubit_test.md](test/features/home/chat/logic/cubit/chat_cubit_test.md) |
| API timestamp parsing (the 3-hour shift) | `test/core/helpers/app_date_time_test.dart` | [app_date_time_test.md](test/core/helpers/app_date_time_test.md) |
| Offline/online detection | `test/core/networks/connectivity_service_test.dart` | [connectivity_service_test.md](test/core/networks/connectivity_service_test.md) |
| Offline cache store | `test/core/cache/offline_cache_test.dart` | [offline_cache_test.md](test/core/cache/offline_cache_test.md) |
| Reels cache fallback | `test/features/home/reels/logic/cubit/reels_cubit_test.dart` | [reels_cubit_test.md](test/features/home/reels/logic/cubit/reels_cubit_test.md) |
| Profile cache fallback | `test/features/home/profile/logic/cubit/profile_cubit_test.dart` | [profile_cubit_test.md](test/features/home/profile/logic/cubit/profile_cubit_test.md) |
| Like count multiplied by comment count | `PostRepository` (API) | Feed/profile/detail/reels/trending all left-join **two** one-to-many relations — `post.likes` and `post.comments` — which is a cartesian product. `comments_count` counted `DISTINCT comment.id`; `likes_count` was a plain `COUNT("like".user_id)`, so it returned likes × comments (6 likes + 2 comments = "12"). Invisible on posts with fewer than two comments, which is why it survived until the "who liked this" list showed the real names next to the number. Nothing was stored, so fixing the query fixed every post at once |
| Reels kept showing a stale like count | `reels_screen._onReelsUpdated` | It accepted a delivery only when the list **length** changed, discarding corrections to reels already on screen. Harmless until reels were cached offline — then the cached list painted first, the live one arrived the same length, and the fresh counts were dropped. Merge rules extracted to the pure `mergeReels` |
| Chat image → fullscreen | `test/features/home/chat/UI/widgets/message_bubble_test.dart` | [message_bubble_test.md](test/features/home/chat/UI/widgets/message_bubble_test.md) |
| Reaction chips + "edited" marker | `test/features/home/chat/UI/widgets/message_reactions_test.dart` | [message_reactions_test.md](test/features/home/chat/UI/widgets/message_reactions_test.md) |
| Chat list re-sort after a delete | `test/features/home/chat/logic/conversation_ordering_test.dart` | [conversation_ordering_test.md](test/features/home/chat/logic/conversation_ordering_test.md) |
| Message delete / edit / react (API) | `src/modules/chat/chat.controller.spec.ts` (NestJS repo) | [chat.controller.spec.md](/Users/magd/apis/riff/src/modules/chat/chat.controller.spec.md) |
| Who-liked-a-post request | `test/features/home/feed/data/repos/like_repo_test.dart` | [like_repo_test.md](test/features/home/feed/data/repos/like_repo_test.md) |
| Like row's two tap targets | `test/features/home/feed/Ui/widgets/post/post_actions_test.dart` | [post_actions_test.md](test/features/home/feed/Ui/widgets/post/post_actions_test.md) |
| Reels list merge rules | `test/features/home/reels/logic/reels_merge_test.dart` | [reels_merge_test.md](test/features/home/reels/logic/reels_merge_test.md) |
| Feed cache fallback | `test/features/home/feed/logic/cubit/feed_cubit_test.dart` | [feed_cubit_test.md](test/features/home/feed/logic/cubit/feed_cubit_test.md) |
| Chat model timestamp normalisation | `test/features/home/chat/data/models/chat_models_test.dart` | [chat_models_test.md](test/features/home/chat/data/models/chat_models_test.md) |
| Duplicate-conversation collapsing | `test/features/home/chat/logic/cubit/conversation_dedupe_test.dart` | [conversation_dedupe_test.md](test/features/home/chat/logic/cubit/conversation_dedupe_test.md) |
| Chats list dedupe wiring | `test/features/home/chat/logic/cubit/chats_list_cubit_test.dart` | [chats_list_cubit_test.md](test/features/home/chat/logic/cubit/chats_list_cubit_test.md) |
| Mark-all-read renders instantly | `test/features/home/notifications/UI/notifications_screen_test.dart` | [notifications_screen_test.md](test/features/home/notifications/UI/notifications_screen_test.md) |
| Read-receipt derivation (API) | `src/modules/chat/message-status.spec.ts` (NestJS repo) | [message-status.spec.md](/Users/magd/apis/riff/src/modules/chat/message-status.spec.md) |

Patterns worth reusing from these:

- **Assert on route names, not screens.** Pump a `MaterialApp` wired to
  `NavigationService.navigatorKey` with a catch-all `onGenerateRoute` that builds
  a stand-in per route name, and record pushes with a `NavigatorObserver`. You get
  real navigation semantics (order, arguments, stack clearing) without booting
  screens that want Firebase and the network.
- **Anything that polls on a real `Timer` must be awaited inside
  `tester.runAsync`.** Under the default fake-async clock the poll never fires and
  the test *hangs* instead of failing — `NavigationService.waitUntilReady` is the
  one to watch. Its `readyTimeout` is `@visibleForTesting` mutable so the
  no-navigator path doesn't sit for 10 seconds.
- **`route.builder(context)` builds a screen widget without mounting it**, so you
  can assert on constructor arguments (`postId`, `commentId`, …) cheaply. To check
  *which* cubit instance a `BlocProvider` shares, mount only the provider around a
  probe child via `SingleChildStatelessWidget.buildWithChild`.
- **Cubits with `AppScopedCubit` ignore `close()`** — use `disposePermanently()`
  in `tearDown`, or a pending `Timer.periodic` will fail the test binding.
- **Use `pumpAndSettle()`, not a single `pump()`, after emitting** — a cubit's
  state stream is asynchronous and one frame can land before `BlocBuilder` sees it.

The NestJS side has unit specs too — run them with `npx jest <path>` (plain
`npm test` also wants a live test database). `ConversationRepository` is covered
by
[conversation.repository.spec.md](/Users/magd/apis/riff/src/modules/chat/repositories/conversation.repository.spec.md).
Timestamps are worth calling out across both repos: **every** API timestamp
column is PostgreSQL `TIMESTAMP` holding UTC, and the wire format is not
consistent about saying so — parse server dates through
`parseServerDateTime`, never `DateTime.parse` directly.

**Deliberately not covered:** `new_user_onboarding_screen.dart` (reaches into `getIt<...>()`
directly in field initializers instead of via constructor injection, and drives `image_picker` +
`permission_handler`), `onboarding_screen.dart` and the `user-prefrences/`
genre/instrument screens (static UI or local selection state, no repo/cubit layer). If any of these
grow real logic worth isolating, apply the same repo/cubit-first approach before reaching for a
full widget test.

---

## Known Bugs Fixed

| Bug | Location | Fix |
|-----|----------|-----|
| TextEditingController disposed during sheet dismiss animation | `GroupDetailsScreen._showEditSheet` | Extracted to `_EditGroupSheet` StatefulWidget — controllers tied to its lifecycle |
| Voice note appears twice in chat | `ChatCubit.sendMedia()` | Check `msg.id` already in list before prepending (socket can beat HTTP response) |
| White screen when sharing from TikTok/Spotify | `HomeLayout` + `ShareReceiverService` | Re-call `init()` on app resume; add 300ms delay before navigation; detect `spotify:` URIs; fallback platform detection from text keywords |
| Group edit crash after saving | `GroupDetailsScreen` | Bottom sheet is now its own `StatefulWidget` |
| Login token debug-log crash | `LoginRepo._handleLoginResponse`, `DioFactory` interceptor | `accessToken.substring(0, 20)` threw `RangeError` for tokens <20 chars, turning a successful login into a reported failure — guarded with a length check before truncating |
| `LoginCubit` state stream untyped | `LoginCubit` | Declared as raw `Cubit<LoginState>` (`T` resolved to `dynamic`) instead of `Cubit<LoginState<LoginResponse>>` |
| `SignupCubit` state stream untyped | `SignupCubit` | Same as above — raw `Cubit<SignupState>` widened to `Cubit<SignupState<void>>` (signup's response payload is never read downstream) |
| Phone OTP + contacts sync removed (2026-07-31) | `WhatsAppService`, `SendPhoneOtp`, `FindContacts` (API); `phone_verify`, onboarding contacts step, feed empty-state sync (Flutter) | Both features were deleted rather than fixed. WhatsApp OTP went through whatsapp-web.js → Baileys → Meta Cloud API and never reached a working state: unofficial clients hit error 463 (`account restricted or missing tctoken`) on every message to a contact with no prior conversation — which is every OTP recipient — and the official Cloud API cannot create an AUTHENTICATION template until the Meta business portfolio is verified. Contacts sync went with it because matching depended on verified phone numbers. Signup now goes straight to `newUserOnboarding`. The `users` table keeps its `phone_number`/`phone_verified`/`phone_otp*` columns (dropping them is destructive and unnecessary); re-adding the feature means restoring from git history plus a verified Meta portfolio. |
| `ForgotPasswordCubit` emit methods un-awaitable | `ForgotPasswordCubit` | `emitForgotPasswordStates`/`emitVerifyOtpState`/`emitResetPasswordState` were declared `void ... async` instead of `Future<void> ... async` — callers (and tests) couldn't `await` completion; widened the return type (backward-compatible, no call site needed to change) |
| Randomly signed out (often right after posting a comment) | `DioFactory` interceptor → `SessionManager` | `/auth/refresh` rotates the refresh token and stores only a hash of the newest one. The interceptor refreshed once **per failed request**, so a burst of 401s (comment + feed + chat list + the 30 s notification poll, against a 15-minute access token) fired several refreshes with the same token — the first rotated it, the rest came back 401 and were treated as "session over", and a loser could write an already-dead refresh token back to storage. `SessionManager.refreshAccessToken()` is now single-flight |
| A failed retry counted as an auth failure | `DioFactory` interceptor | The whole refresh-and-retry block sat in one `try`, so a retried request failing for its own reasons (404, 500, timeout) fell into the forced-logout branch |
| Forced sign-out never reached the login screen | `NavigationService` / `RiffMaterialApp` | `MaterialApp` was built with `PushNotificationService.navigatorKey` while the 401 handler pushed through `NavigationService.navigatorKey` — a key attached to nothing, so `currentState` was always null and the redirect silently did nothing. One key now |
| "Mark all as read" worked until you'd opened the notifications screen once | `AppRouter`, `PushNotificationService` | Both provided the `NotificationsCubit` **singleton** with `BlocProvider(create:)`, which closes it when the route pops. A closed cubit can never emit again and GetIt keeps returning it, so every later `markAllRead()` hit `if (!isClosed)` and did nothing, with no error. All singleton providers are `.value`, and the cubits carry `AppScopedCubit` so a future `create:` can't reintroduce it |
| Chat list frozen / can't message after opening a chat from a notification | `PushNotificationService`, `user_profile_screen` | Same closed-singleton bug, on `ChatsListCubit` |
| Can't send messages after opening the app from a message notification | `ChatSocketService`, `ChatCubit`, `HomeLayout` | `ChatGateway.handleConnection` verifies the access token and disconnects on failure. Access tokens live 15 minutes, so opening from a push — by definition after a pause — handshook with a dead token. HTTP recovered via the 401 interceptor (history loaded, screen looked fine), the socket never did, and every `send_message` emit vanished until restart. Sockets now connect through `SessionManager.validAccessToken()` and reconnect on `onAccessTokenRefreshed` |
| Duplicate socket handlers after every app resume | `ChatSocketService.connect` | `io.io()` multiplexes on the URI and returns the *same* Socket for a namespace it already knows; re-calling it on resume without disposing stacked another full set of `on(...)` handlers, so messages arrived several times over |
| Notification tap dropped on a slow cold start | `PushNotificationService` | A fixed `Future.delayed(800ms)` guess before navigating; now waits for the navigator via `NavigationService.waitUntilReady()` |
| Notification tap opened a blank/authenticated screen while signed out | `PushNotificationService` | Taps are parked and replayed from `HomeLayout` after login |
| Flagged-comment push with no `comment_id` crashed the tap handler | `PushNotificationService` → `NotificationRoute` | `int.tryParse(commentIdStr!)` ran as soon as the type matched; routing is now a pure, total function |
| `setUpGetIt()` not awaited in `main()` | `main_development.dart`, `main_production.dart` | It awaits `DioFactory.getDio()` internally while `HomeLayout.initState` resolves singletons — a fast first frame could reach GetIt before registration finished |
| `post.g.dart` couldn't be regenerated | `Post.commentsCount` | `@JsonKey(defaultValue: 0)` on a `String?` field made json_serializable emit `as String? ?? 0`, which doesn't compile; the checked-in `.g.dart` had been hand-patched, so any `build_runner` run broke the build |
| Everything displayed ~3 hours early (UTC+3) | `app_date_time.dart`, chat/notification models | Two causes, both landing on the same symptom. Timestamps **with** `Z`: `DateTime.parse` returns `isUtc == true`, and the chat bubble / chat list / last-seen formatters read `.hour`/`.minute` straight off it without converting to local. Timestamps **without** a designator (the API sends both shapes): `DateTime.parse` reads them as local, so UTC digits became the wrong instant — and `timeAgo` then called `.toUtc()` on the result, shifting it again. Now normalised once at the parsing boundary: interpret as UTC, return local |
| A user appears twice in chats — one thread with messages, one empty | `chat.controller.ts`, `conversation.repository.ts`, `conversation_dedupe.dart` | `POST /chat/conversations/direct` checked for an existing conversation and created one if absent as two separate awaits, so two racing requests both created one. Declining a message request deleted only the recipient's participant row, leaving a one-sided conversation `findDirect` could no longer match, so the next message started a fresh one. Fixed with an advisory-locked atomic find-or-create, decline deleting the whole direct conversation, orphans filtered out of the listings, and a client-side dedupe for accounts that already have the duplicated rows. Migration `1790500000000` cleans up production data |
| Direct conversation picked at random when duplicates exist | `ConversationRepository.findDirect` | Unordered `getOne()` — the same pair could land in the thread with their history one time and the empty one the next. Now ordered by most recent activity, then oldest |
| No API unit spec could run | `package.json` jest block | Missing `moduleNameMapper` for the `src/...` path alias, so every spec failed to resolve its imports; only the e2e config worked |
| "Mark all as read" needed a manual refresh before the rows looked read | `NotificationsCubit` | Two causes. It emitted only *after* awaiting the request and swallowed every error, so a failure looked like a success that hadn't happened yet — now optimistic, with rollback and a reported result. And a fetch already in flight (the 30 s poll, or the `silentRefresh()` HomeLayout runs on returning from the screen) could land between the optimistic update and the server commit and repaint every row unread. Local changes now bump an epoch counter; a fetch that started before the bump discards its result |
| `NotificationsScreen` untestable | `NotificationsScreen` | Called `FirebaseMessaging.instance.getNotificationSettings()` directly in `initState`; now an injectable `notificationsDenied` callback defaulting to the real call, per the pattern in the login tests |
| Signed out on a flaky connection | `SessionManager._performRefresh` | One 401 from `/auth/refresh` ended the session, and one transient failure was the end of the attempt. But `/auth/refresh` **rotates** the token, so a 401 can equally mean this caller lost a race with a concurrent refresh — and a rejection that arrives while the device is offline is more likely a captive portal than a revoked session. Refresh now retries transient failures on a 1s/3s/6s backoff, requires two confirmed rejections, ignores rejections while offline, and re-tries with the newer token when storage rotated it mid-flight |
| Every screen showed an error page instead of content when the connection dropped | feed / reels / chats / search / profile cubits | Nothing was cached and every failure emitted a failure state, so a lost connection replaced a screen the user had been reading a second earlier with "Something went wrong". Each cubit now falls back to `OfflineCache`, keeps whatever is already on screen when a refresh fails, and re-fetches on reconnect |
| A refresh on a dying connection blanked the feed | `FeedCubit.getPosts` | `refresh: true` cleared the post list *before* the request, so a failed pull-to-refresh left an empty feed. The list is cleared only when the replacement arrives |
| Cached feed showed once then vanished; reels and profile posts never cached | `OfflineCache._write` | The in-memory mirror stored whatever `toJson()` returned. With json_serializable's default `explicit_to_json: false`, `Post.toJson()` leaves nested `author`/`likes`/`comments` as **objects**, not maps. `json.encode` fixes that on the way to disk (its default `toEncodable` calls `toJson()`), so the disk copy was always right — but every read served from the mirror threw inside `Post.fromJson` and was swallowed as "nothing cached". Chat worked throughout because its models have hand-written `toJson()`s. `_write` now encodes first and mirrors the re-decoded payload, so memory and disk cannot disagree |
| Own-profile posts cached inconsistently | `ProfileCubit.loadUserPosts` | The "is this me?" lookup ran inside the synchronous success callback, so the cache write only started a microtask later and raced any read that followed. Resolved once up front instead |
| "Is my message sending, sent, or lost?" | `ChatCubit`, `MessageBubble` | Text messages were fire-and-forget into the socket and the composer cleared regardless; media showed one generic "sending" bubble unattached to the message. Sends are now optimistic, correlated by `client_id`, rendered dimmed while pending, and turned into a tappable retry when they fail |
| A deleted post stayed in the feed | `PostEvents`, feed/reels/discover/profile cubits, `DeletePost` (API) | Deleting a post removed it from the profile it was deleted from and nowhere else — every other list kept its own copy until the next refetch, and the offline cache kept it indefinitely. `PostEvents.deletions` is now a process-wide broadcast: `DeletePostCubit` announces the id on success and `FeedCubit` / `ReelsCubit` / `SearchCubit` / `ProfileCubit` / `UserProfileCubit` each drop it locally and prune their cache bucket. Shares of the post are *kept* — `posts.original_post_id` is `ON DELETE SET NULL`, so the API flags every share `original_post_deleted` before deleting the original and the client renders `UnavailablePostCard` instead of an empty share |
| Deleting a message left the chat list sorted by it | `chat.controller.ts` (`deleteMessage`), `ChatsListCubit`, `conversation_ordering.dart` | `conversations.last_message_at` kept pointing at the deleted message, so the conversation stayed where it was and its row still previewed text nobody could see, until the next full refresh. Deletion now walks `last_message_at` back to the newest surviving message (or null), broadcasts it with the new preview on `message_deleted`, and the client re-sorts. This is the one chat event that moves a conversation *down* the list, so unlike `onNewMessage` it can't be a "move to position 0" — hence the separate `sortConversationsByRecency` |
| Read receipts stuck on one check — recipient had read the messages | `chat.controller.ts` (`serializeMsg`), `message-status.ts` | Read state only ever existed as a transient `message_status` socket event, upgraded in memory by whoever had that exact chat open at the time. Nothing persisted it and `serializeMsg` had **no `status` field**, so `MessageStatusX.fromString(null)` fell through to `sent` and every message reset to one check as soon as the sender reopened the chat. Status is now derived server-side from `conversation_participants.last_read_at`, returned on every message, and `GET .../messages` also emits a read receipt so a client whose socket hasn't come up still clears the sender's ticks. Voice notes go through the media-upload endpoint, which now carries the same status as a socket-sent text message |

---

## Env Variables Reference (API)

```
# Server
PORT=3000
NODE_ENV=production
CORS_ORIGIN=

# Database
DATABASE_URL=postgres://...

# JWT
JWT_ACCESS_TOKEN_SECRET=
JWT_ACCESS_TOKEN_EXPIRATION_MS=900000
JWT_REFRESH_TOKEN_SECRET=
JWT_REFRESH_TOKEN_EXPIRATION_MS=604800000
JWT_RESET_TOKEN_SECRET=
JWT_RESET_TOKEN_EXPIRATION_MS=600000

# Google OAuth
GOOGLE_WEB_CLIENT_ID=
GOOGLE_WEB_CLIENT_SECRET=
GOOGLE_ANDROID_CLIENT_ID=
GOOGLE_IOS_CLIENT_ID=

# Cloudinary
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=

# Firebase (FCM push notifications)
FIREBASE_SERVICE_ACCOUNT_JSON=

# Spotify
SPOTIFY_CLIENT_ID=
SPOTIFY_CLIENT_SECRET=

```

---

## Checklist for Any New Feature

- [ ] Read existing files in the feature area before writing
- [ ] Follow folder structure: `UI/`, `data/models/`, `data/repos/`, `logic/cubit/`
- [ ] Register new repo/cubit in `dependency_injection.dart`
- [ ] Add all endpoint strings to `ApiConstants`
- [ ] Add all UI strings to both `intl_en.arb` AND `intl_ar.arb`
- [ ] Use `S.of(context).key` — never hardcode strings
- [ ] Use `MediaUrl.resolve()` for all image URLs
- [ ] Use `.w`, `.h`, `.r` for all sizes (screenutil)
- [ ] Write DB migration if schema changes needed
- [ ] Add Cloudinary upload service method if new media type needed
- [ ] Test dedup logic for any real-time (socket) + HTTP combination
- [ ] Decide what the feature shows with no connection — cache the last-known-good
      copy via `OfflineCache` and fall back to it, rather than emitting a failure
- [ ] **Tests** — new feature: write unit tests for the repo (mock the API service) and cubit (mock the repo), plus widget tests for the screen/widgets, following the pattern in `lib/features/auth/login/` (see Testing section above). Updating existing code: update whichever of those tests cover the changed behavior instead of leaving them stale or deleting them
