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
- Run `flutter gen-l10n` after editing ARB files to regenerate

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

## Known Bugs Fixed

| Bug | Location | Fix |
|-----|----------|-----|
| TextEditingController disposed during sheet dismiss animation | `GroupDetailsScreen._showEditSheet` | Extracted to `_EditGroupSheet` StatefulWidget — controllers tied to its lifecycle |
| Voice note appears twice in chat | `ChatCubit.sendMedia()` | Check `msg.id` already in list before prepending (socket can beat HTTP response) |
| White screen when sharing from TikTok/Spotify | `HomeLayout` + `ShareReceiverService` | Re-call `init()` on app resume; add 300ms delay before navigation; detect `spotify:` URIs; fallback platform detection from text keywords |
| Group edit crash after saving | `GroupDetailsScreen` | Bottom sheet is now its own `StatefulWidget` |

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
