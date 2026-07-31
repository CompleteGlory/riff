import 'package:flutter/foundation.dart';

/// Where a tapped push notification should take the user.
enum NotificationRouteKind {
  /// A specific conversation.
  chatConversation,

  /// A comment of the user's that was flagged.
  flaggedComment,

  /// A post of the user's that was flagged.
  flaggedPost,

  /// Anything else — likes, comments, follows: the notifications list.
  notificationsList,
}

/// The destination derived from an FCM payload.
///
/// This is deliberately a plain value object with no Firebase or Flutter
/// dependency: the routing rules are the part that keeps regressing, and they
/// are only testable if resolving them doesn't require a live app.
@immutable
class NotificationRoute {
  const NotificationRoute({
    required this.kind,
    this.conversationId,
    this.commentId,
    this.postId,
    this.title,
    this.body,
  });

  final NotificationRouteKind kind;
  final String? conversationId;
  final int? commentId;
  final int? postId;
  final String? title;
  final String? body;

  static const notifications =
      NotificationRoute(kind: NotificationRouteKind.notificationsList);

  /// Resolves the destination for an FCM `data` payload.
  ///
  /// [notificationTitle] / [notificationBody] come from the `notification`
  /// block when present; the data payload's own `title`/`body` are the
  /// fallback (data-only messages).
  ///
  /// Never throws: a malformed payload falls back to the notifications list.
  /// The previous implementation force-unwrapped `comment_id` as soon as the
  /// type was `comment_flagged`, so a flagged-comment push that arrived
  /// without one crashed the tap handler instead of opening anything.
  factory NotificationRoute.fromData(
    Map<String, dynamic> data, {
    String? notificationTitle,
    String? notificationBody,
  }) {
    String? str(String key) {
      final value = data[key];
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    int? id(String key) {
      final raw = str(key);
      return raw == null ? null : int.tryParse(raw);
    }

    final type = str('notification_type');
    final conversationId = str('conversation_id');
    final commentId = id('comment_id');
    final postId = id('post_id');
    final title = notificationTitle ?? str('title');
    final body = notificationBody ?? str('body');

    if (type == 'chat_message' && conversationId != null) {
      return NotificationRoute(
        kind: NotificationRouteKind.chatConversation,
        conversationId: conversationId,
      );
    }

    if (commentId != null &&
        (type == 'comment_flagged' || type == 'admin_notice')) {
      return NotificationRoute(
        kind: NotificationRouteKind.flaggedComment,
        commentId: commentId,
        postId: postId,
        title: title,
        body: body,
      );
    }

    if (postId != null && (type == 'post_flagged' || type == 'admin_notice')) {
      return NotificationRoute(
        kind: NotificationRouteKind.flaggedPost,
        postId: postId,
        title: title,
        body: body,
      );
    }

    return notifications;
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationRoute &&
      other.kind == kind &&
      other.conversationId == conversationId &&
      other.commentId == commentId &&
      other.postId == postId &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode =>
      Object.hash(kind, conversationId, commentId, postId, title, body);

  @override
  String toString() => 'NotificationRoute($kind, conv: $conversationId, '
      'comment: $commentId, post: $postId)';
}
