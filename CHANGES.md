# Changelog

All notable changes to the Riff Flutter app are documented here.

---

## [Unreleased] – June 2026

### Added

**Comment Reports (Admin Dashboard)**
- Admin dashboard has a new **Posts / Comments** sub-tab in the Reports screen.
- `GET /admin/reports/comments` — lists all comment reports with reporter + comment preview.
- Admin can **Delete Comment** and **Notify Author** per report.
- Notifying an author sends a `comment_flagged` push + in-app notification with `comment_id` in the FCM payload.

**Push Notification Tap Routing**
- All three FCM delivery states (foreground, background, terminated) now deep-link to the correct screen:
  - `comment_flagged` or `admin_notice` with `comment_id` → `FlaggedCommentDetailScreen`
  - `post_flagged` or `admin_notice` with `post_id` → `FlaggedPostDetailScreen`
  - All other types → `NotificationsScreen`

**Real-Time Notification Refresh**
- `PushNotificationService.refreshStream` emits on every foreground FCM message.
- `HomeLayout` subscribes and calls `NotificationsCubit.silentRefresh()` immediately — no restart needed.

**FlaggedCommentDetailScreen**
- Shown when user taps a `comment_flagged` in-app tile or FCM banner.
- Fetches `GET /api/comments/:id` with full relations (`user`, `post`, `post.author`).
- Shows an orange "FLAGGED COMMENT" header card + the parent post.
- Falls back gracefully if the comment was deleted.

**New In-App Notification Tile Types**
- `like` — avatar + "liked your post/comment", taps → sender profile
- `comment` — avatar + "commented on your post", taps → sender profile
- `comment_flagged` — orange theme, "FLAGGED COMMENT" chip, always routes to detail screen

**New Backend Endpoints**
- `GET /api/comments/:id` — public; returns comment with `user`, `post`, `post.author`
- `GET /admin/reports/comments` — admin list of comment reports
- `PATCH /admin/reports/comments/:id` — update report status
- `DELETE /admin/comments/:id` — admin delete a comment

### Fixed

**Self-Notification Guard**
- Liking or commenting on your own post no longer sends a notification to yourself.
- Guard added in `like-entity.ts`, `create-comment.ts`, and `SendUserNotification.execute()`.

**NestJS Circular Dependency**
- `LikesModule`, `CommentsModule`, and `FollowsModule` now import `NotificationsModule` via `forwardRef()`.
- Resolves the `UndefinedModuleException` that caused server startup to fail.

### Refactored

**API Calling Pattern (Flutter)**
- Introduced `FeedbackRepo` for bug report and feature request submissions.
- Introduced `ReportRepo` for post and comment report submissions.
- Added `BugReportCubit`, `FeatureRequestCubit`, `ReportCubit`.
- All four screens (`bug_report`, `feature_request`, `report_post`, `report_comment`) now delegate to cubits — no raw Dio calls in UI files.
- `SuggestedUsersRepo.findContacts()` replaces the inline Dio call in `FeedEmptyState`.

**Dead Code Removal (Flutter)**
- `lib/features/home/feed/logic/feed/feed_cubit.dart` marked as deprecated (unreferenced duplicate of `logic/cubit/feed/feed_cubit.dart`).
- `LikeCubit` and `LikeState` removed from DI and marked deprecated — `PostCubit` consumes `LikeRepo` directly; no UI ever resolved `LikeCubit` via `getIt`.
- `.DS_Store` files excluded via existing `.gitignore` rule.

**Dead Code Removal (NestJS)**
- Removed unused `JwtAuthGuard` import from `auth.controller.ts` (guard is global via `app.module.ts`; no per-route usage needed).
- Removed plaintext OTP logging from `send-phone-otp.ts` and `verify-phone-otp.ts` (security: OTP and phone number were emitted at `Logger.debug` level).

---

## [Previous] – Post View Analytics

### Added

**Post View Analytics**
- `viewsCount` field added to `Post` model (mapped from `views_count` JSON key, default 0)
- `ViewTracker` singleton for session-scoped deduplication — avoids re-sending the view API call if the same post widget rebuilds or re-enters the list
- View count badge (eye icon + formatted count) displayed on post thumbnails in profile screen, other-user profile screen, and search screen
- Eye icon + count shown inline in `PostActions` row on feed posts
- `ViewTracker.instance.track(postId)` called in `PostItem.initState` and `ReelItem.initState`
- `ApiService.recordView(postId)` — fires a `POST /api/posts/{id}/view` request (fire-and-forget)
- `ApiService.getTrendingPost()` — `GET /api/posts/trending`
- `FeedRepo.recordView` and `FeedRepo.getTrendingPost` methods
- `FeedCubit.loadTrending()` — fetches trending post and stores it; called on refresh and initial load

**Trending Post Card**
- `TrendingPostCard` widget inserted at position 2 in the home feed (after the second post)
- Displays a 🔥 "Trending" badge with lime accent border and view count in the header
- Uses sentinel object pattern (`_trendingSlot`) in `FeedScreenBody` to avoid type coupling in the mixed feed list
- Tapping the card navigates to `PostDetailScreen`

**Reels Enhancements**
- Report and Edit/Delete options now available from reels via the existing `showPostOptions()` bottom sheet
- "View Full Post" button (article icon) on the reel action column opens the post in `PostDetailScreen`
- Both actions pass `HomeCubit` context when available so back-navigation state is preserved

---

## [Previous]

### Fixed
- Notification delivery corrected when switching between user accounts — notifications now always arrive for the active user
- CI pipeline fixed to correctly resolve Flutter dependencies before build step

### Added
- Push notifications for new followers, post likes, and comments
- FCM token registration on login; token cleared on logout
- Notification permission request on app launch (iOS + Android)
