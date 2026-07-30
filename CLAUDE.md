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
  networks/
    api_constants.dart           # ALL endpoint strings go here
    dio_factory.dart             # Dio instance with auth interceptor
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

**API base URL:** `https://riff-production-08f7.up.railway.app` (Railway deployment)

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
- Never call `pumpAndSettle()` after a transition onto a screen with a repeating `Timer.periodic`
  or a looping `AnimationController` (e.g. a countdown, a blinking cursor) — it never settles. Use
  a bounded `tester.pump(someDuration)` instead.

### Other auth features

The same repo/cubit/widget layering was applied to the rest of `lib/features/auth/`:

| Feature | Repo test | Cubit test | Widget tests |
| --- | --- | --- | --- |
| `forgot_password` | [forgot_password_repo_test.md](test/features/auth/forgot_password/data/repos/forgot_password_repo_test.md) | [forgot_password_cubit_test.md](test/features/auth/forgot_password/logic/cubit/forgot_password_cubit_test.md) | [forgot_password_form_field_test.md](test/features/auth/forgot_password/UI/widgets/forgot_password_form_field_test.md), [reset_password_form_fields_test.md](test/features/auth/forgot_password/UI/widgets/reset_password_form_fields_test.md), [forgot_password_bloc_listener_test.md](test/features/auth/forgot_password/UI/widgets/forgot_password_bloc_listener_test.md), [request_otp_bloc_listener_test.md](test/features/auth/forgot_password/UI/widgets/request_otp_bloc_listener_test.md), [reset_password_bloc_listener_test.md](test/features/auth/forgot_password/UI/widgets/reset_password_bloc_listener_test.md) |
| `signup` | [signup_repo_test.md](test/features/auth/signup/data/repos/signup_repo_test.md) | [signup_cubit_test.md](test/features/auth/signup/logic/cubit/signup_cubit_test.md) | [signup_form_fields_test.md](test/features/auth/signup/UI/widgets/signup_form_fields_test.md), [signup_bloc_listener_test.md](test/features/auth/signup/UI/widgets/signup_bloc_listener_test.md) |
| `phone_verify` | [phone_verify_repo_test.md](test/features/auth/phone_verify/data/repos/phone_verify_repo_test.md) | [phone_verify_cubit_test.md](test/features/auth/phone_verify/logic/cubit/phone_verify_cubit_test.md) | [phone_verify_screen_test.md](test/features/auth/phone_verify/UI/phone_verify_screen_test.md) |
| `new_user_onboarding` | [suggested_users_repo_test.md](test/features/auth/new_user_onboarding/data/repos/suggested_users_repo_test.md) | *(no cubit — screen calls the repo directly)* | *(not covered — see below)* |

### Phone confirmation from account settings

The same phone flow is reachable from two places, and the tests are split to match:

| Layer | Test | Doc |
| --- | --- | --- |
| Model (`GET /api/users/me` parsing) | `test/features/home/profile/user_profile_phone_fields_test.dart` | [user_profile_phone_fields_test.md](test/features/home/profile/user_profile_phone_fields_test.md) |
| Widget — conditional entry | `test/features/home/account_settings/UI/account_settings_phone_tile_test.dart` | [account_settings_phone_tile_test.md](test/features/home/account_settings/UI/account_settings_phone_tile_test.md) |

`PhoneVerifyScreen`/`PhoneOtpScreen` are shared between signup and settings rather than
duplicated. They take an optional `onVerified` callback: null keeps the signup behaviour
(`pushNamedAndRemoveUntil` to onboarding), and `app_router.dart` passes one for
`Routes.confirmPhone` that pops back with `true` so account settings can retire the entry. This is
the same optional-callback-with-a-real-default pattern used for the plugin-backed calls above.

Two things worth knowing before touching this area:

- `phone_verified` missing from the `me` payload parses as **true**, not false. Absent means
  "unknown", and unknown must stay quiet — defaulting to false would prompt every user on a
  client running against an older API.
- `_SectionHeader` in `account_settings_screen.dart` renders `title.toUpperCase()`, so widget
  tests must match the uppercased string, not the raw ARB value.

**Deliberately not covered:** `new_user_onboarding_screen.dart` (reaches into `getIt<...>()`
directly in field initializers instead of via constructor injection, and drives `image_picker` +
`flutter_contacts` + `permission_handler`), `onboarding_screen.dart` and the `user-prefrences/`
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
| `ForgotPasswordCubit` emit methods un-awaitable | `ForgotPasswordCubit` | `emitForgotPasswordStates`/`emitVerifyOtpState`/`emitResetPasswordState` were declared `void ... async` instead of `Future<void> ... async` — callers (and tests) couldn't `await` completion; widened the return type (backward-compatible, no call site needed to change) |
| Phone OTP never arrived on WhatsApp, but the API reported success | `WhatsAppService` (API), `PhoneVerifyCubit`, `phone_verify_screen.dart` | Two separate bugs. **(1) Silent-success lie:** `sendMessage()` logged the OTP and `return`ed normally when the client wasn't ready, so `POST /api/auth/phone/send-otp` answered `200 {message:'OTP sent via WhatsApp'}` and the app advanced to the code-entry screen for a code that only existed in a Railway log line. It now throws `ServiceUnavailableException` (503) → cubit emits the `WHATSAPP_UNAVAILABLE` sentinel → localized snackbar. **(2) Client wedged after auth:** Chrome ran without `--disable-dev-shm-usage`, so the 64MB `/dev/shm` in the container starved WhatsApp Web's initial app-state sync and the renderer stalled *after* `authenticated`. `ready` is emitted from the same `exposeFunction` callback as `authenticated` in whatsapp-web.js, so the throw between them was swallowed by Puppeteer and never logged — the only symptom was `AUTHENTICATED` with no `READY`, forever. Added the container Chrome flags, a `READY_TIMEOUT_MS` watchdog that logs page/connection diagnostics and rebuilds the client, `disconnected` auto-restart with bounded backoff, and `getNumberId()` + `message_ack` so a send is verified rather than assumed |
| Chrome's cache filling the WhatsApp session volume | `WhatsAppService` (API) | `LocalAuth`'s directory doubles as Chrome's `user-data-dir`, so every cached byte landed on the same 500MB Railway volume holding the linked session — it hit 274MB, and a full volume unlinks WhatsApp and forces a QR rescan. Pointed `--disk-cache-dir` at ephemeral container disk (`/tmp`) so the volume only carries session state, and added a boot-time prune of the disposable cache dirs to reclaim what had already accumulated (`--disk-cache-size` alone capped the rate but not the destination, and never covered the GPU/shader caches Chrome writes into the profile regardless). The prune is a strict allowlist, never a glob: the same profile holds WhatsApp's login state in `IndexedDB`/`Local Storage`/`Local State`, so a glob would unlink the account. It runs before Chrome launches and never throws — failing to reclaim disk must not take OTP delivery down |
| `puppeteer.executablePath()` await dropped | `WhatsAppService.initializeClient` | Chrome got the literal path `[object Promise]` and never launched (`Browser was not found at the configured executablePath`). puppeteer 25 resolves a Promise here, but types `executablePath` as an overloaded callable loose enough that the missing `await` type-checks clean and only fails at runtime — `tsc` and eslint both passed. Restored the `await` plus an assert that the resolved value is a non-empty string |

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

# WhatsApp (phone OTP delivery, via whatsapp-web.js + headless Chrome)
# Must point inside the mounted Railway Volume, or the linked session is lost
# on every redeploy and the QR has to be rescanned.
WHATSAPP_SESSION_PATH=/data/.whatsapp-session
# Optional. Seconds-to-ready watchdog before the client is declared wedged
# and rebuilt. Default 120000.
WHATSAPP_READY_TIMEOUT_MS=
# Optional. How long a send waits for a still-starting client. Default 20000.
WHATSAPP_SEND_WAIT_MS=
# Optional. Bounded client rebuild attempts. Default 3.
WHATSAPP_MAX_RESTARTS=
# The sending WhatsApp account's own number, digits only, international form.
# Setting it links by 8-character PAIRING CODE instead of QR — the only
# workable mode on a hosted service. WhatsApp rotates a QR every ~20s, which is
# less time than it takes to copy the payload out of a log viewer, render it and
# scan it, so QR relinking presents as "corrupt/unscannable" codes. Unset it to
# fall back to QR.
WHATSAPP_PAIR_PHONE_NUMBER=
# Optional. Where Chrome's HTTP cache goes. Default /tmp/wwebjs-chrome-cache.
# Must stay OFF the mounted volume: the LocalAuth dir doubles as Chrome's
# user-data-dir, so a cache pointed at /data fills the volume that holds the
# linked session, and a full volume forces a QR rescan.
WHATSAPP_CHROME_CACHE_DIR=
# Optional escape hatch. Pin a specific WhatsApp Web build from the wa-version
# mirror (e.g. 2.3000.1023204620) when the version whatsapp-web.js defaults to
# stops reaching `ready`.
WHATSAPP_WEB_VERSION=
# LOCAL DEV ONLY. 'true' logs the OTP instead of sending it, so the flow can be
# tested without a linked phone. Never enable in production — it puts live OTP
# codes in the logs.
WHATSAPP_LOG_OTP=
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
- [ ] **Tests** — new feature: write unit tests for the repo (mock the API service) and cubit (mock the repo), plus widget tests for the screen/widgets, following the pattern in `lib/features/auth/login/` (see Testing section above). Updating existing code: update whichever of those tests cover the changed behavior instead of leaving them stale or deleting them
