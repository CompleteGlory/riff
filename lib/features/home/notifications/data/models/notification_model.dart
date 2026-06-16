class NotificationSender {
  final String id;
  final String username;
  final String fullName;
  final String? profileImageUrl;

  const NotificationSender({
    required this.id,
    required this.username,
    required this.fullName,
    this.profileImageUrl,
  });

  factory NotificationSender.fromJson(Map<String, dynamic> j) =>
      NotificationSender(
        id: j['id'] as String,
        username: j['username'] as String? ?? '',
        fullName: j['full_name'] as String? ?? '',
        profileImageUrl: j['profile_image_url'] as String?,
      );
}

class NotificationModel {
  final int id;
  // 'follow' | 'follow_request' | 'follow_accepted' | 'complete_profile'
  // | 'admin_notice' | 'post_flagged'
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final NotificationSender? sender; // null for system / admin notifications
  /// 'not_following' | 'pending' | 'following'
  final String followBackStatus;
  /// Extra data for admin_notice / post_flagged: {'title': '...', 'body': '...'}
  final Map<String, String>? metadata;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.sender,
    this.followBackStatus = 'not_following',
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) {
    final senderData = j['sender'] as Map<String, dynamic>?;
    final rawMeta = j['metadata'];
    Map<String, String>? metadata;
    if (rawMeta is Map) {
      metadata = rawMeta.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return NotificationModel(
      id: j['id'] as int,
      type: j['type'] as String,
      isRead: j['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
          DateTime.now(),
      sender: senderData != null
          ? NotificationSender.fromJson(senderData)
          : null,
      followBackStatus: j['follow_back_status'] as String? ?? 'not_following',
      metadata: metadata,
    );
  }

  NotificationModel copyWith({String? followBackStatus, bool? isRead}) =>
      NotificationModel(
        id: id,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        sender: sender,
        followBackStatus: followBackStatus ?? this.followBackStatus,
        metadata: metadata,
      );
}

class NotificationsResponse {
  final List<NotificationModel> data;
  final int unreadCount;

  const NotificationsResponse({required this.data, required this.unreadCount});

  factory NotificationsResponse.fromJson(Map<String, dynamic> j) =>
      NotificationsResponse(
        data: (j['data'] as List<dynamic>? ?? [])
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        unreadCount: j['unread_count'] as int? ?? 0,
      );
}
