// ignore_for_file: prefer_final_fields, use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/time_ago.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/follow/logic/cubit/follow_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/comments/comment_cubit.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/features/home/notifications/data/models/notification_model.dart';
import 'package:riff/features/home/notifications/logic/cubit/notifications_cubit.dart';
import 'package:riff/features/home/user_profile/ui/user_profile_screen.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/auth/user-prefrences/instruments_screen.dart';
import 'package:riff/features/home/notifications/UI/post_by_id_screen.dart';
import 'package:riff/features/home/notifications/UI/flagged_comment_detail_screen.dart';
import 'package:riff/generated/l10n.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cubit already provided via BlocProvider.value from HomeLayout
    return const _NotificationsBody();
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).notificationsTitle),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationsCubit>().markAllRead(),
            child: Text(S.of(context).markAllRead,
                style: TextStyles.font12Medium.copyWith(
                    color: isDark ? Colors.white70 : ColorManager.primaryBlack)),
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (ctx, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationsError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(state.message, style: TextStyles.font14Medium),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ctx.read<NotificationsCubit>().load(),
                  child: Text(S.of(context).retryBtn),
                ),
              ]),
            );
          }
          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 64.r, color: ColorManager.lighterGrey),
                  const SizedBox(height: 16),
                  Text(S.of(context).noNotificationsYet,
                      style: TextStyles.font16Medium.copyWith(
                          color: ColorManager.normalGrey)),
                ]),
              );
            }
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return RefreshIndicator(
              onRefresh: () => ctx.read<NotificationsCubit>().load(),
              color: isDark ? ColorManager.accent : ColorManager.primaryBlack,
              backgroundColor: isDark ? const Color(0xFF252525) : ColorManager.white,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: state.notifications.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: ColorManager.lighterGrey),
                itemBuilder: (_, i) {
                  final notif = state.notifications[i];
                  return Dismissible(
                    key: ValueKey(notif.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) =>
                        ctx.read<NotificationsCubit>().removeNotification(notif.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20.w),
                      color: Colors.red.shade400,
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 24),
                    ),
                    child: _NotificationTile(
                      key: ValueKey(notif.id),
                      notification: notif,
                      notifsCubit: ctx.read<NotificationsCubit>(),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final NotificationsCubit notifsCubit;
  const _NotificationTile({
    super.key,
    required this.notification,
    required this.notifsCubit,
  });

  String _avatarUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.startsWith('http') ? raw : '${ApiConstants.apiBASEURL}$raw';
  }

  String _message(BuildContext context) {
    switch (notification.type) {
      case 'follow':
        return S.of(context).startedFollowingYou;
      case 'follow_request':
        return S.of(context).requestedToFollowYou;
      case 'follow_accepted':
        return S.of(context).acceptedYourFollowRequest;
      case 'complete_profile':
        return S.of(context).completeYourProfile;
      case 'like':
        final hasComment = notification.metadata?['comment_id'] != null;
        return hasComment ? S.of(context).likedYourComment : S.of(context).likedYourPost;
      case 'comment':
        return S.of(context).commentedOnYourPost;
      default:
        return '';
    }
  }

  bool get _isSystem => notification.type == 'complete_profile';
  bool get _isAdminNotice => notification.type == 'admin_notice';
  bool get _isPostFlagged => notification.type == 'post_flagged';
  bool get _isCommentFlagged => notification.type == 'comment_flagged';


  void _goToProfile(BuildContext context) {
    if (_isSystem || _isAdminNotice || _isPostFlagged || _isCommentFlagged || notification.sender == null) return;
    HomeCubit? homeCubit;
    try { homeCubit = context.read<HomeCubit>(); } catch (_) {}
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => homeCubit != null
          ? BlocProvider.value(
              value: homeCubit,
              child: UserProfileScreen(userId: notification.sender!.id))
          : UserProfileScreen(userId: notification.sender!.id),
    ));
  }

  void _goToPost(BuildContext context, {bool openComments = false}) {
    notifsCubit.markRead(notification.id);
    _resolveAndNavigate(context, openComments: openComments);
  }

  Future<void> _resolveAndNavigate(BuildContext context, {bool openComments = false}) async {
    // 1. Try post_id directly from metadata.
    final postIdStr = notification.metadata?['post_id'];
    final postId = postIdStr != null ? int.tryParse(postIdStr) : null;
    if (postId != null) {
      _pushPostScreen(context, postId: postId, openComments: openComments);
      return;
    }

    // 2. Try comment_id → fetch comment → extract post.id.
    final commentIdStr = notification.metadata?['comment_id'];
    final commentId = commentIdStr != null ? int.tryParse(commentIdStr) : null;

    if (commentId != null) {
      // Show a brief loading indicator while we resolve the post.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).loadingPost),
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      try {
        final result = await getIt<CommentCubit>().getComment(commentId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        result.when(
          success: (data) {
            final postData = data['post'] as Map<String, dynamic>?;
            final rawId = postData?['id'];
            final resolvedId =
                rawId != null ? int.tryParse(rawId.toString()) : null;
            if (resolvedId == null) {
              _showNavError(context, 'Post not found.');
            } else {
              _pushPostScreen(context,
                  postId: resolvedId, openComments: openComments);
            }
          },
          failure: (err) =>
              _showNavError(context, err.message ?? 'Could not load post.'),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showNavError(context, 'Failed to load post: $e');
        }
      }
      return;
    }

    // 3. Nothing to navigate to.
    _showNavError(context, 'No post linked to this notification.');
  }

  void _pushFlaggedCommentScreen(BuildContext context) {
    notifsCubit.markRead(notification.id);
    final commentId = int.tryParse(notification.metadata?['comment_id'] ?? '');
    final postId = int.tryParse(notification.metadata?['post_id'] ?? '');
    HomeCubit? homeCubit;
    try { homeCubit = context.read<HomeCubit>(); } catch (_) {}
    final screen = FlaggedCommentDetailScreen(
      commentId: commentId,
      postId: postId,
      flagTitle: notification.metadata?['title'],
      flagBody: notification.metadata?['body'],
    );
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => homeCubit != null
          ? BlocProvider.value(value: homeCubit, child: screen)
          : screen,
    ));
  }

  void _pushPostScreen(BuildContext context, {required int postId, bool openComments = false}) {
    HomeCubit? homeCubit;
    try { homeCubit = context.read<HomeCubit>(); } catch (_) {}
    final screen = PostByIdScreen(postId: postId, openComments: openComments);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => homeCubit != null
          ? BlocProvider.value(value: homeCubit, child: screen)
          : screen,
    ));
  }

  void _showNavError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final bg = notification.isRead
        ? Colors.transparent
        : cs.secondary.withValues(alpha: isDark ? 0.08 : 0.06);

    // ── Admin notice tile ──────────────────────────────────────────────────
    if (_isAdminNotice) {
      final title = notification.metadata?['title'] ?? 'Admin Notice';
      final body = notification.metadata?['body'] ?? '';
      final hasContent = notification.metadata?['comment_id'] != null ||
          notification.metadata?['post_id'] != null;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (hasContent) {
            if (notification.metadata?['comment_id'] != null) {
              _pushFlaggedCommentScreen(context);
            } else {
              _goToPost(context);
            }
          }
        },
        child: Container(
        color: notification.isRead
            ? Colors.transparent
            : const Color(0xFFC6FF00).withValues(alpha: 0.06),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent left bar
              Container(width: 3, color: const Color(0xFFC6FF00)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shield icon
                      Container(
                        width: 40.r,
                        height: 40.r,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC6FF00).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.shield_rounded,
                          color: const Color(0xFFC6FF00),
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC6FF00)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    color: const Color(0xFFC6FF00),
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                timeAgo(notification.createdAt.toString()),
                                style: TextStyles.font12Medium.copyWith(
                                    color: ColorManager.normalGrey),
                              ),
                            ]),
                            SizedBox(height: 5.h),
                            Text(
                              title,
                              style: TextStyles.font14semiBold.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color),
                            ),
                            if (body.isNotEmpty) ...[
                              SizedBox(height: 3.h),
                              Text(
                                body,
                                style: TextStyles.font12Medium.copyWith(
                                    color: ColorManager.normalGrey),
                              ),
                            ],
                            if (hasContent) ...[
                              SizedBox(height: 6.h),
                              Row(children: [
                                Text(
                                  notification.metadata?['comment_id'] != null
                                      ? 'Tap to view comment'
                                      : 'Tap to view post',
                                  style: TextStyle(
                                    color: const Color(0xFFC6FF00),
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 10.r,
                                    color: const Color(0xFFC6FF00)),
                              ]),
                            ],
                          ],
                        ),
                      ),
                      if (!notification.isRead)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Container(
                            width: 7.r,
                            height: 7.r,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC6FF00),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      );
    }

    // ── Post flagged tile ──────────────────────────────────────────────────
    if (_isPostFlagged) {
      final title = notification.metadata?['title'] ?? 'Your post was flagged';
      final body = notification.metadata?['body'] ?? '';
      final hasPost = notification.metadata?['post_id'] != null;
      return GestureDetector(
        onTap: () => _goToPost(context),
        child: Container(
        color: notification.isRead
            ? Colors.transparent
            : Colors.orange.withValues(alpha: 0.06),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: Colors.orange),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40.r,
                        height: 40.r,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.flag_rounded,
                          color: Colors.orange,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  'FLAGGED',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                timeAgo(notification.createdAt.toString()),
                                style: TextStyles.font12Medium.copyWith(
                                    color: ColorManager.normalGrey),
                              ),
                            ]),
                            SizedBox(height: 5.h),
                            Text(
                              title,
                              style: TextStyles.font14semiBold.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color),
                            ),
                            if (body.isNotEmpty) ...[
                              SizedBox(height: 3.h),
                              Text(
                                body,
                                style: TextStyles.font12Medium.copyWith(
                                    color: ColorManager.normalGrey),
                              ),
                            ],
                            if (hasPost) ...[
                              SizedBox(height: 6.h),
                              Row(children: [
                                Text(
                                  'Tap to view post',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 10.r, color: Colors.orange),
                              ]),
                            ],
                          ],
                        ),
                      ),
                      if (!notification.isRead)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Container(
                            width: 7.r,
                            height: 7.r,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      );
    }

    // ── Comment flagged tile ───────────────────────────────────────────────
    if (_isCommentFlagged) {
      final title = notification.metadata?['title'] ?? 'Your comment was flagged';
      final body = notification.metadata?['body'] ?? '';
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _pushFlaggedCommentScreen(context),
        child: Container(
        color: notification.isRead
            ? Colors.transparent
            : Colors.orange.withValues(alpha: 0.06),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: Colors.orange),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40.r,
                        height: 40.r,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.orange,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  'FLAGGED COMMENT',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                timeAgo(notification.createdAt.toString()),
                                style: TextStyles.font12Medium.copyWith(
                                    color: ColorManager.normalGrey),
                              ),
                            ]),
                            SizedBox(height: 5.h),
                            Text(
                              title,
                              style: TextStyles.font14semiBold.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color),
                            ),
                            if (body.isNotEmpty) ...[
                              SizedBox(height: 3.h),
                              Text(
                                body,
                                style: TextStyles.font12Medium.copyWith(
                                    color: ColorManager.normalGrey),
                              ),
                            ],
                            SizedBox(height: 6.h),
                            Row(children: [
                              Text(
                                'Tap to view comment',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 10.r, color: Colors.orange),
                            ]),
                          ],
                        ),
                      ),
                      if (!notification.isRead)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Container(
                            width: 7.r,
                            height: 7.r,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      );
    }

    // System notification (complete_profile) — full-width row
    if (_isSystem) {
      return Container(
        color: bg,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: cs.secondary.withValues(alpha: 0.15),
            child: Icon(Icons.music_note_rounded,
                color: cs.secondary, size: 22.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(S.of(context).completeYourProfile,
                  style: TextStyles.font14semiBold.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
              SizedBox(height: 2.h),
              Text(S.of(context).addGenresInstruments,
                  style: TextStyles.font12Medium.copyWith(
                      color: ColorManager.normalGrey)),
              SizedBox(height: 3.h),
              Text(timeAgo(notification.createdAt.toString()),
                  style: TextStyles.font12Medium.copyWith(
                      color: ColorManager.normalGrey)),
            ]),
          ),
          SizedBox(width: 10.w),
          _ActionArea(notification: notification, notifsCubit: notifsCubit),
        ]),
      );
    }

    // ── Unknown / legacy system notification (no sender, unrecognised type) ──
    // These are old DB rows whose type didn't match any known handler above.
    // Render them as a tappable orange-flagged tile so they never look like
    // a broken follow notification.
    if (notification.sender == null) {
      final title = notification.metadata?['title'] ?? 'Admin notice';
      final body = notification.metadata?['body'] ?? '';
      final hasPost = notification.metadata?['post_id'] != null;
      return GestureDetector(
        onTap: () => _goToPost(context),
        child: Container(
          color: notification.isRead
              ? Colors.transparent
              : Colors.orange.withValues(alpha: 0.06),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: Colors.orange),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.w, vertical: 14.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(Icons.flag_rounded,
                              color: Colors.orange, size: 20.r),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    'FLAGGED',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  timeAgo(notification.createdAt.toString()),
                                  style: TextStyles.font12Medium.copyWith(
                                      color: ColorManager.normalGrey),
                                ),
                              ]),
                              SizedBox(height: 5.h),
                              Text(
                                title,
                                style: TextStyles.font14semiBold.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color),
                              ),
                              if (body.isNotEmpty) ...[
                                SizedBox(height: 3.h),
                                Text(
                                  body,
                                  style: TextStyles.font12Medium.copyWith(
                                      color: ColorManager.normalGrey),
                                ),
                              ],
                              if (hasPost) ...[
                                SizedBox(height: 6.h),
                                Row(children: [
                                  Text(
                                    'Tap to view post',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      size: 10.r, color: Colors.orange),
                                ]),
                              ],
                            ],
                          ),
                        ),
                        if (!notification.isRead)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Container(
                              width: 7.r,
                              height: 7.r,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final avatarUrl = _avatarUrl(notification.sender?.profileImageUrl);
    final isSocialInteraction =
        notification.type == 'like' || notification.type == 'comment';

    return GestureDetector(
      onTap: isSocialInteraction ? () {
        if (notification.type == 'like') {
          _goToPost(context, openComments: false);
        } else if (notification.type == 'comment') {
          _goToPost(context, openComments: true);
        }
      } : null,
      child: Container(
      color: bg,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        GestureDetector(
          onTap: () => _goToProfile(context),
          child: CircleAvatar(
            radius: 22.r,
            backgroundColor: ColorManager.lighterGrey,
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
                    (notification.sender?.username.isNotEmpty == true)
                        ? notification.sender!.username[0].toUpperCase()
                        : '?',
                    style: TextStyles.font15semiBold)
                : null,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '@${notification.sender?.username ?? ''} ',
                  style: TextStyles.font14semiBold.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                TextSpan(
                  text: ' ${_message(context)}',
                  style: TextStyles.font14Medium.copyWith(
                      color: ColorManager.normalGrey),
                ),
              ]),
            ),
            SizedBox(height: 3.h),
            Text(timeAgo(notification.createdAt.toString()),
                style: TextStyles.font12Medium.copyWith(
                    color: ColorManager.normalGrey)),
          ]),
        ),
        SizedBox(width: 10.w),
        // Action widget on the right — same width slot for all types
        _ActionArea(notification: notification, notifsCubit: notifsCubit),
      ]),
    ),
    );
  }
}

// ── Action area (right side of tile) ─────────────────────────────────────────

class _ActionArea extends StatelessWidget {
  final NotificationModel notification;
  final NotificationsCubit notifsCubit;
  const _ActionArea({required this.notification, required this.notifsCubit});

  @override
  Widget build(BuildContext context) {
    switch (notification.type) {
      case 'follow_request':
        return _AcceptDeclineButtons(
          notification: notification,
          notifsCubit: notifsCubit,
        );
      case 'follow':
      case 'follow_accepted':
        return _FollowBackButton(
          notification: notification,
          notifsCubit: notifsCubit,
        );
      case 'complete_profile':
        return _PillBtn(
          label: 'Set up',
          filled: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InstrumentsScreen()),
          ),
        );
      case 'like':
      case 'comment':
      case 'admin_notice':
      case 'post_flagged':
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Accept / Decline ──────────────────────────────────────────────────────────

class _AcceptDeclineButtons extends StatefulWidget {
  final NotificationModel notification;
  final NotificationsCubit notifsCubit;
  const _AcceptDeclineButtons({
    required this.notification,
    required this.notifsCubit,
  });

  @override
  State<_AcceptDeclineButtons> createState() => _AcceptDeclineButtonsState();
}

class _AcceptDeclineButtonsState extends State<_AcceptDeclineButtons> {
  bool _loading = false;
  String? _done; // 'accepted' | 'declined'

  Future<void> _act(bool accept) async {
    setState(() => _loading = true);
    try {
      final followCubit = getIt<FollowCubit>();
      if (accept) {
        await followCubit.acceptFollow(widget.notification.sender!.id);
      } else {
        await followCubit.rejectFollow(widget.notification.sender!.id);
      }
      if (mounted) {
        setState(() { _loading = false; _done = accept ? 'accepted' : 'declined'; });
        // On decline: remove the notification entirely
        // On accept: keep it visible so the user can follow back
        if (!accept) {
          unawaited(widget.notifsCubit.removeNotification(widget.notification.id));
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // After accepting, morph into the Follow Back button
    if (_done == 'accepted') {
      return _FollowBackButton(
        notification: widget.notification,
        notifsCubit: widget.notifsCubit,
      );
    }
    if (_done == 'declined') {
      return Text(S.of(context).declined,
          style: TextStyles.font12Medium.copyWith(color: ColorManager.normalGrey));
    }
    if (_loading) {
      return const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _PillBtn(label: 'Confirm', filled: true, onTap: () => _act(true)),
      SizedBox(width: 8.w),
      _PillBtn(label: S.of(context).deleteBtn, filled: false, onTap: () => _act(false)),
    ]);
  }
}

// ── Follow-back button (Instagram-style) ──────────────────────────────────────

class _FollowBackButton extends StatefulWidget {
  final NotificationModel notification;
  final NotificationsCubit notifsCubit;
  const _FollowBackButton({
    required this.notification,
    required this.notifsCubit,
  });

  @override
  State<_FollowBackButton> createState() => _FollowBackButtonState();
}

class _FollowBackButtonState extends State<_FollowBackButton> {
  late String _status;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.notification.followBackStatus;
  }

  @override
  void didUpdateWidget(_FollowBackButton old) {
    super.didUpdateWidget(old);
    // Sync from model when parent rebuilds (e.g. after socket push)
    if (old.notification.followBackStatus !=
        widget.notification.followBackStatus) {
      _status = widget.notification.followBackStatus;
    }
  }

  Future<void> _follow() async {
    // Optimistic
    setState(() { _status = 'following'; });
    widget.notifsCubit.updateFollowBackStatus(
        widget.notification.id, 'following');
    try {
      await getIt<FollowCubit>().follow(widget.notification.sender!.id);
      // FollowCubit.follow already maps status; if the cubit state is FollowSuccess
      // we can read the resolved status from it
      final followState = getIt<FollowCubit>().state;
      if (followState is FollowSuccess && mounted && followState.status != _status) {
        setState(() => _status = followState.status);
        widget.notifsCubit.updateFollowBackStatus(
            widget.notification.id, followState.status);
      }
    } catch (_) {
      // Revert
      if (mounted) {
        setState(() => _status = 'not_following');
        widget.notifsCubit.updateFollowBackStatus(
            widget.notification.id, 'not_following');
      }
    }
  }

  Future<void> _unfollow() async {
    setState(() { _status = 'not_following'; });
    widget.notifsCubit.updateFollowBackStatus(
        widget.notification.id, 'not_following');
    try {
      await getIt<FollowCubit>().unfollow(widget.notification.sender!.id);
      // Refresh badge immediately so count drops after unfollow
      widget.notifsCubit.silentRefresh();
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'following');
        widget.notifsCubit.updateFollowBackStatus(
            widget.notification.id, 'following');
      }
    }
  }

  void _showUnfollowSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36.w, height: 4.h,
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              color: ColorManager.lighterGrey,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Text('@${widget.notification.sender!.username}',
              style: TextStyles.font14semiBold),
          SizedBox(height: 20.h),
          GestureDetector(
            onTap: () { Navigator.pop(context); _unfollow(); },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: ColorManager.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: ColorManager.red.withValues(alpha: 0.2)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.person_remove_outlined,
                    color: ColorManager.red, size: 18.r),
                SizedBox(width: 8.w),
                Text(S.of(context).unfollowBtn,
                    style: TextStyles.font14semiBold.copyWith(
                        color: ColorManager.red)),
              ]),
            ),
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(S.of(context).cancelBtn,
                  textAlign: TextAlign.center,
                  style: TextStyles.font14semiBold),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2));
    }

    switch (_status) {
      case 'following':
        return _PillBtn(
          label: S.of(context).followingStatus,
          filled: true,
          showChevron: true,
          onTap: _showUnfollowSheet,
        );
      case 'pending':
        return _PillBtn(label: 'Requested', filled: false, onTap: null);
      default:
        return _PillBtn(
          label: 'Follow Back',
          filled: true,
          onTap: _follow,
        );
    }
  }
}

// ── Compact theme-aware button ────────────────────────────────────────────────

class _PillBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback? onTap;
  final bool showChevron;
  const _PillBtn({
    required this.label,
    required this.filled,
    required this.onTap,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size(60.w, 32.h)),
      padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: 12.w, vertical: 0)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStateProperty.all(TextStyles.font12Medium),
    );

    final child = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label),
      if (showChevron) ...[
        SizedBox(width: 2.w),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 15),
      ],
    ]);

    if (filled) {
      return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom().merge(compact),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom().merge(compact),
      child: child,
    );
  }
}
