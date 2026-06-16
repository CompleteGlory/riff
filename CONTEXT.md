# Riff – Session Context (June 2026)

## What was built in this session

All three apps were modified together: **NestJS backend** (`/Users/magd/apis/riff`),
**Flutter user app** (`/Users/magd/apps/flutter/riff`),
**Flutter admin dashboard** (`/Users/magd/apps/flutter/riff_admin_dashboard`).

---

### Features completed

#### 1. Comment reports in admin dashboard
- Admin dashboard now has a **Posts / Comments** sub-tab in the Reports screen.
- Comment reports are fetched from `GET /admin/reports/comments`.
- Admin can **Delete Comment** and **Notify Author** per report.
- Notify Author sends a `comment_flagged` push + in-app notification to the comment author.

#### 2. Like / Comment push notifications (with self-notification guard)
- Liking a post/comment sends a `like` notification to the author.
- Commenting on a post sends a `comment` notification to the post author.
- **Self-notifications are skipped** (`post.author_id !== userId` check in use-cases + `recipientId === senderId` guard in `SendUserNotification`).
- Circular module dependency fixed with `forwardRef(() => NotificationsModule)` in `LikesModule`, `CommentsModule`, and `FollowsModule`.

#### 3. Push notification tap routing (all three states)
- **Foreground** (local banner tap): routes to the correct detail screen.
- **Background** (FCM banner tap): `onMessageOpenedApp` → smart router.
- **Terminated** (app closed, tap FCM banner): `getInitialMessage` + 800 ms delay → smart router.

Smart router logic (`PushNotificationService._navigateFromMessage`):
- `comment_flagged` OR (`admin_notice` + `comment_id`) → `FlaggedCommentDetailScreen`
- `post_flagged` OR (`admin_notice` + `post_id`) → `FlaggedPostDetailScreen`
- everything else → `NotificationsScreen`

#### 4. Real-time in-app notification refresh
- `PushNotificationService.refreshStream` emits whenever a foreground FCM message arrives.
- `HomeLayout` subscribes and calls `notifsCubit.silentRefresh()` immediately — no restart needed.

#### 5. FlaggedCommentDetailScreen
- Shown when user taps a `comment_flagged` in-app notification tile OR taps the FCM banner.
- Fetches `GET /api/comments/:id` (with `user`, `post`, `post.author` relations).
- Shows an orange "FLAGGED COMMENT" card + the parent post below it.
- Falls back gracefully if comment is deleted.

#### 6. In-app notification tiles
New tile types added to `NotificationsScreen`:
- `like` tile — shows avatar, "liked your post/comment", taps → sender profile.
- `comment` tile — shows avatar, "commented on your post", taps → sender profile.
- `comment_flagged` tile — orange, "FLAGGED COMMENT" chip, chat bubble icon, always taps → `FlaggedCommentDetailScreen`.
- `post_flagged` tile — already existed, unchanged.
- `admin_notice` tile — unchanged; now also routes to `FlaggedCommentDetailScreen` if `comment_id` present in metadata.

---

### Notification type union (backend entity)

```typescript
export type NotificationType =
  | 'follow' | 'follow_request' | 'follow_accepted'
  | 'complete_profile' | 'admin_notice'
  | 'post_flagged' | 'comment_flagged'   // ← comment_flagged is new
  | 'like' | 'comment';
```

---

### Files changed

#### Backend — `/Users/magd/apis/riff/src/`

| File | Change |
|---|---|
| `modules/notifications/entities/notification.entity.ts` | Added `'like'`, `'comment'`, `'comment_flagged'` to `NotificationType` |
| `modules/notifications/use-cases/send-user-notification.ts` | **CREATED** — shared service: saves in-app notification + sends FCM, skips self |
| `modules/notifications/notifications.module.ts` | Added `User` entity, `SendUserNotification` to providers + exports |
| `modules/admin/use-cases/notify-user.ts` | Added `'comment_flagged'` to valid types list |
| `modules/admin/admin.controller.ts` | `notifyUser` endpoint now accepts `@Body('comment_id')` and `@Body('post_id')` |
| `modules/admin/use-cases/admin-delete-comment.ts` | **CREATED** — deletes a comment by ID (admin only) |
| `modules/likes/use-cases/like-entity.ts` | Rewritten — sends like notification, skips self, skips duplicate likes |
| `modules/likes/likes.module.ts` | Added `forwardRef(() => NotificationsModule)`, `Post`, `Comment` entities |
| `modules/comments/use-cases/create-comment.ts` | Rewritten — sends comment notification, skips self |
| `modules/comments/use-cases/get-comment.ts` | **CREATED** — returns comment with `user`, `post`, `post.author` relations |
| `modules/comments/use-cases/index.ts` | Added `GetComment` export |
| `modules/comments/comments.module.ts` | Added `forwardRef(() => NotificationsModule)`, `Post`, `GetComment` |
| `modules/comments/comments.controller.ts` | Added `GET /comments/:id` route (no auth guard — public) |
| `modules/comments/repositories/comment.repository.ts` | Added `findById(id)` method with full relations |
| `modules/follows/follows.module.ts` | Changed `NotificationsModule` import to `forwardRef(() => NotificationsModule)` |
| `modules/reports/entities/comment-report.entity.ts` | **CREATED** — `CommentReport` entity |
| `modules/reports/repositories/comment-report.repository.ts` | **CREATED** — `findAll`, `create`, `updateStatus` with full relations |
| `modules/reports/reports.controller.ts` | Added `POST /reports/comments` endpoint |
| `modules/reports/reports.module.ts` | Added `CommentReport` entity + repository |
| `modules/admin/use-cases/update-comment-report-status.ts` | **CREATED** — updates comment report status |
| `modules/admin/use-cases/get-all-reports.ts` | Added `getCommentReports(status?)` method |
| `modules/admin/admin.controller.ts` | Added `GET /admin/reports/comments`, `PATCH /admin/reports/comments/:id`, `DELETE /admin/comments/:id` |
| `modules/admin/admin.module.ts` | Registered all new use-cases and entities |

#### Flutter user app — `/Users/magd/apps/flutter/riff/lib/`

| File | Change |
|---|---|
| `core/services/push_notification_service.dart` | Full rewrite — `refreshStream`, smart FCM router, `_pendingForegroundMessage`, deep navigation to comment/post detail |
| `riff_app.dart` | Added `navigatorKey: PushNotificationService.navigatorKey` to `MaterialApp` |
| `features/home/core/UI/home_layout.dart` | Added `_pushRefreshSub` subscribing to `PushNotificationService.refreshStream` |
| `features/home/notifications/ui/notifications_screen.dart` | Added `like`, `comment`, `comment_flagged` tiles; updated `_goToFlaggedPost` to route to comment detail; `_isCommentFlagged` getter; `HitTestBehavior.opaque` on admin_notice GestureDetector |
| `features/home/notifications/UI/flagged_comment_detail_screen.dart` | **CREATED** — fetches `GET /api/comments/:id`, shows flagged comment card + parent post |

#### Flutter admin dashboard — `/Users/magd/apps/flutter/riff_admin_dashboard/lib/`

| File | Change |
|---|---|
| `features/dashboard/data/models/report_models.dart` | Added `CommentReport`, `ReportComment` models |
| `features/dashboard/data/repos/dashboard_repo.dart` | Added `getCommentReports`, `updateCommentReportStatus`, `deleteComment`; `notifyUser` now accepts `commentId`/`postId` |
| `features/dashboard/logic/cubit/dashboard_cubit.dart` | Added comment report actions; `notifyUser` now accepts `commentId`/`postId` |
| `features/dashboard/logic/cubit/dashboard_state.dart` | Added `commentReports`, `commentStatusFilter` fields to `DashboardLoaded` |
| `features/dashboard/ui/dashboard_screen.dart` | Added Posts / Comments sub-tabs to Reports section |
| `features/dashboard/ui/post_reports/comment_reports_tab.dart` | **CREATED** — comment reports list with Notify Author + Delete Comment actions, sends `comment_flagged` type |

---

### Pending action required

**Restart the NestJS server** before testing. The self-notification fix and `comment_flagged` type are correct in code but won't take effect until the server reloads.

To test the full flow:
1. Restart server (`npm run start:dev`)
2. In admin dashboard → Reports → Comments → "Notify Author" on any comment report
3. The user receives an orange "FLAGGED COMMENT" push notification
4. Tapping the FCM banner → directly opens `FlaggedCommentDetailScreen`
5. Tapping the in-app tile (Notifications screen) → also opens `FlaggedCommentDetailScreen`
