// Chat data models — Conversation, Message, ChatParticipant
import 'package:riff/core/helpers/app_date_time.dart';
import 'package:riff/core/networks/api_constants.dart';

class ChatParticipant {
  final String userId;
  final String role; // 'member' | 'admin'
  final bool isRequest;
  final String? username;
  final String? fullName;
  final String? profileImageUrl;

  const ChatParticipant({
    required this.userId,
    required this.role,
    required this.isRequest,
    this.username,
    this.fullName,
    this.profileImageUrl,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> j) => ChatParticipant(
        userId: j['user_id'] as String,
        role: j['role'] as String? ?? 'member',
        isRequest: j['is_request'] as bool? ?? false,
        username: j['username'] as String?,
        fullName: j['full_name'] as String?,
        profileImageUrl: ApiConstants.resolveUrl(j['profile_image_url'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'role': role,
        'is_request': isRequest,
        'username': username,
        'full_name': fullName,
        'profile_image_url': profileImageUrl,
      };
}

class ConversationOtherUser {
  final String id;
  final String? username;
  final String? fullName;
  final String? profileImageUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  const ConversationOtherUser({
    required this.id,
    this.username,
    this.fullName,
    this.profileImageUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ConversationOtherUser.fromJson(Map<String, dynamic> j) =>
      ConversationOtherUser(
        id: j['id'] as String,
        username: j['username'] as String?,
        fullName: j['full_name'] as String?,
        profileImageUrl: ApiConstants.resolveUrl(j['profile_image_url'] as String?),
        isOnline: j['is_online'] as bool? ?? false,
        lastSeen: parseServerDateTime(j['last_seen'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'profile_image_url': profileImageUrl,
        // Presence is a live fact; a cached copy of it would be a lie the next
        // time the app opens offline, so it is never restored as "online".
        'is_online': false,
        'last_seen': lastSeen?.toUtc().toIso8601String(),
      };

  ConversationOtherUser copyWith({bool? isOnline, DateTime? lastSeen}) =>
      ConversationOtherUser(
        id: id,
        username: username,
        fullName: fullName,
        profileImageUrl: profileImageUrl,
        isOnline: isOnline ?? this.isOnline,
        lastSeen: lastSeen ?? this.lastSeen,
      );
}

class Conversation {
  final String id;
  final String type; // 'direct' | 'group'
  final String? name;
  final String? description;
  final String? imageUrl;
  final bool isRequest;
  final DateTime createdAt;
  final List<ChatParticipant> participants;
  final ConversationOtherUser? otherUser;

  /// When this conversation last had a message — the key the chat list is
  /// sorted on. Mutable alongside [latestMessage] because deleting the newest
  /// message moves it *backwards*, to whatever is now on top.
  DateTime? lastMessageAt;
  ChatMessage? latestMessage;
  int unreadCount;

  /// The instant this conversation sorts by. A conversation nobody has spoken
  /// in yet — or one whose only message was just deleted — falls back to when
  /// it was created rather than to the bottom of the list.
  DateTime get sortedAt => lastMessageAt ?? createdAt;

  Conversation({
    required this.id,
    required this.type,
    this.name,
    this.description,
    this.imageUrl,
    required this.isRequest,
    this.lastMessageAt,
    required this.createdAt,
    required this.participants,
    this.otherUser,
    this.latestMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] as String,
        type: j['type'] as String? ?? 'direct',
        name: j['name'] as String?,
        description: j['description'] as String?,
        imageUrl: j['image_url'] as String?,
        isRequest: j['is_request'] as bool? ?? false,
        lastMessageAt: parseServerDateTime(j['last_message_at'] as String?),
        createdAt: parseServerDateTimeOr(j['created_at'] as String?),
        participants: (j['participants'] as List<dynamic>? ?? [])
            .map((p) => ChatParticipant.fromJson(p as Map<String, dynamic>))
            .toList(),
        otherUser: j['other_user'] != null
            ? ConversationOtherUser.fromJson(j['other_user'] as Map<String, dynamic>)
            : null,
        // Use num? cast before toInt() because PostgreSQL COUNT returns a
        // bigint that some JSON decoders parse as double (e.g., 1.0 → double),
        // which would cause `as int?` to silently return null and default to 0.
        unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
      )
        ..latestMessage = j['latest_message'] != null
            ? ChatMessage.fromJson(
                j['latest_message'] as Map<String, dynamic>)
            : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'is_request': isRequest,
        'last_message_at': lastMessageAt?.toUtc().toIso8601String(),
        'created_at': createdAt.toUtc().toIso8601String(),
        'participants': participants.map((p) => p.toJson()).toList(),
        'other_user': otherUser?.toJson(),
        'latest_message': latestMessage?.toJson(),
        'unread_count': unreadCount,
      };

  Conversation withOtherUserPresence(bool online, {DateTime? lastSeen}) => Conversation(
        id: id,
        type: type,
        name: name,
        description: description,
        imageUrl: imageUrl,
        isRequest: isRequest,
        lastMessageAt: lastMessageAt,
        createdAt: createdAt,
        participants: participants,
        otherUser: otherUser?.copyWith(
            isOnline: online,
            lastSeen: lastSeen ?? (online ? null : otherUser?.lastSeen)),
        latestMessage: latestMessage,
        unreadCount: unreadCount,
      );

  String get displayName {
    if (type == 'group') return name ?? 'Group';
    return otherUser?.username ?? otherUser?.fullName ?? 'Unknown';
  }

  String? get displayImageUrl {
    if (type == 'group') return imageUrl;
    return otherUser?.profileImageUrl;
  }

  bool get isGroup => type == 'group';
}

class MessageSender {
  final String id;
  final String? username;
  final String? fullName;
  final String? profileImageUrl;

  const MessageSender({
    required this.id,
    this.username,
    this.fullName,
    this.profileImageUrl,
  });

  factory MessageSender.fromJson(Map<String, dynamic> j) => MessageSender(
        id: j['id'] as String,
        username: j['username'] as String?,
        fullName: j['full_name'] as String?,
        profileImageUrl: ApiConstants.resolveUrl(j['profile_image_url'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'profile_image_url': profileImageUrl,
      };
}

/// One person's reaction to one message.
///
/// A user holds at most one reaction per message — reacting again with a
/// different emoji replaces it — so the identity of a reaction is the user,
/// not the emoji.
class MessageReaction {
  final String emoji;
  final String userId;
  final String? username;
  final String? fullName;

  const MessageReaction({
    required this.emoji,
    required this.userId,
    this.username,
    this.fullName,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> j) => MessageReaction(
        emoji: j['emoji'] as String? ?? '',
        userId: j['user_id'] as String? ?? '',
        username: j['username'] as String?,
        fullName: j['full_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'user_id': userId,
        'username': username,
        'full_name': fullName,
      };

  String get displayName => username ?? fullName ?? '';
}

/// The reactions on one message, grouped into the chips the bubble draws:
/// one chip per distinct emoji, with how many people picked it.
class ReactionSummary {
  const ReactionSummary({
    required this.emoji,
    required this.count,
    required this.reactedByMe,
  });

  final String emoji;
  final int count;
  final bool reactedByMe;

  /// Groups [reactions] in first-seen order, so chips don't jump around as
  /// people react.
  static List<ReactionSummary> from(
    List<MessageReaction> reactions,
    String? myId,
  ) {
    final order = <String>[];
    final counts = <String, int>{};
    final mine = <String>{};
    for (final r in reactions) {
      if (!counts.containsKey(r.emoji)) order.add(r.emoji);
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
      if (myId != null && myId.isNotEmpty && r.userId == myId) mine.add(r.emoji);
    }
    return order
        .map((e) => ReactionSummary(
              emoji: e,
              count: counts[e]!,
              reactedByMe: mine.contains(e),
            ))
        .toList();
  }
}

enum MessageType { text, image, video, audio, file, link }

extension MessageTypeX on MessageType {
  static MessageType fromString(String s) {
    switch (s) {
      case 'image': return MessageType.image;
      case 'video': return MessageType.video;
      case 'audio': return MessageType.audio;
      case 'file': return MessageType.file;
      case 'link': return MessageType.link;
      default: return MessageType.text;
    }
  }

  String get value {
    switch (this) {
      case MessageType.image: return 'image';
      case MessageType.video: return 'video';
      case MessageType.audio: return 'audio';
      case MessageType.file: return 'file';
      case MessageType.link: return 'link';
      case MessageType.text: return 'text';
    }
  }
}

/// 'sent' = saved on server | 'delivered' = device received | 'read' = seen
enum MessageStatus { sent, delivered, read }

extension MessageStatusX on MessageStatus {
  static MessageStatus fromString(String? s) {
    switch (s) {
      case 'delivered': return MessageStatus.delivered;
      case 'read': return MessageStatus.read;
      default: return MessageStatus.sent;
    }
  }
}

/// Where a message is in the *local* send pipeline, as opposed to
/// [MessageStatus], which is where the server says it is.
///
/// A message the user just typed exists on screen before it exists anywhere
/// else. [pending] is that window — the bubble renders dimmed with a clock so
/// the send is visibly in progress rather than silently maybe-happening — and
/// [failed] is what it becomes when the send never landed, so the user gets an
/// explicit retry instead of a message they believe was delivered.
enum MessageDelivery { complete, pending, failed }

class ChatMessage {
  final String id;
  final String conversationId;
  final MessageType type;
  final String? content;
  final String? mediaUrl;
  final String? fileName;
  final int? duration; // seconds
  final bool isDeleted;
  final DateTime createdAt;
  final MessageSender? sender;
  final MessageStatus status;

  /// When the sender last rewrote the text, or null if they never have.
  /// Presence — not a comparison against [createdAt] — is what draws the
  /// "edited" marker, so a message saved twice for unrelated reasons is never
  /// mislabelled.
  final DateTime? editedAt;

  /// Everyone who has reacted to this message, in the order they reacted.
  final List<MessageReaction> reactions;

  /// Client-generated correlation id for an optimistic message.
  ///
  /// The socket echoes it back on the server's copy (`client_id`), which is how
  /// the real message replaces the optimistic one instead of appearing beside
  /// it. Null on anything that came from the server unprompted.
  final String? clientId;

  /// Local send state. See [MessageDelivery].
  final MessageDelivery delivery;

  /// On-device path of the media being uploaded, so a pending image or voice
  /// note renders from disk instead of waiting for a URL that doesn't exist yet.
  final String? localMediaPath;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.fileName,
    this.duration,
    required this.isDeleted,
    required this.createdAt,
    this.sender,
    this.status = MessageStatus.sent,
    this.editedAt,
    this.reactions = const [],
    this.clientId,
    this.delivery = MessageDelivery.complete,
    this.localMediaPath,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        conversationId: j['conversation_id'] as String,
        type: MessageTypeX.fromString(j['type'] as String? ?? 'text'),
        content: j['content'] as String?,
        mediaUrl: ApiConstants.resolveUrl(j['media_url'] as String?),
        fileName: j['file_name'] as String?,
        duration: j['duration'] as int?,
        isDeleted: j['is_deleted'] as bool? ?? false,
        createdAt: parseServerDateTimeOr(j['created_at'] as String?),
        sender: j['sender'] != null
            ? MessageSender.fromJson(j['sender'] as Map<String, dynamic>)
            : null,
        status: MessageStatusX.fromString(j['status'] as String?),
        editedAt: parseServerDateTime(j['edited_at'] as String?),
        reactions: (j['reactions'] as List<dynamic>? ?? const [])
            .map((r) => MessageReaction.fromJson(
                Map<String, dynamic>.from(r as Map)))
            .toList(),
        clientId: j['client_id'] as String?,
      );

  /// Serialises the server-visible fields, for the offline message cache.
  /// Local-only send state is deliberately dropped: a pending message that was
  /// never confirmed must not come back looking sent.
  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'type': type.value,
        'content': content,
        'media_url': mediaUrl,
        'file_name': fileName,
        'duration': duration,
        'is_deleted': isDeleted,
        'created_at': createdAt.toUtc().toIso8601String(),
        'sender': sender?.toJson(),
        'status': status.name,
        'edited_at': editedAt?.toUtc().toIso8601String(),
        'reactions': reactions.map((r) => r.toJson()).toList(),
      };

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageStatus? status,
    MessageDelivery? delivery,
    String? mediaUrl,
    DateTime? createdAt,
    DateTime? editedAt,
    List<MessageReaction>? reactions,
    bool? isDeleted,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        conversationId: conversationId,
        type: type,
        content: content ?? this.content,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        fileName: fileName,
        duration: duration,
        isDeleted: isDeleted ?? this.isDeleted,
        createdAt: createdAt ?? this.createdAt,
        sender: sender,
        status: status ?? this.status,
        editedAt: editedAt ?? this.editedAt,
        reactions: reactions ?? this.reactions,
        clientId: clientId,
        delivery: delivery ?? this.delivery,
        localMediaPath: localMediaPath,
      );

  ChatMessage withStatus(MessageStatus s) => copyWith(status: s);

  /// True while the message only exists on this device.
  bool get isPending => delivery == MessageDelivery.pending;

  /// True when the send failed and the user can retry it.
  bool get hasFailed => delivery == MessageDelivery.failed;

  /// True once the sender has rewritten the text at least once.
  bool get isEdited => editedAt != null;

  /// Only text can be rewritten — replacing an image is a new message, not an
  /// edit — and only while it exists on the server and hasn't been deleted.
  bool get canBeEdited =>
      (type == MessageType.text || type == MessageType.link) &&
      !isDeleted &&
      delivery == MessageDelivery.complete;

  String get preview {
    if (isDeleted) return 'Message deleted';
    switch (type) {
      case MessageType.text: return content ?? '';
      case MessageType.image: return '📷 Photo';
      case MessageType.video: return '🎥 Video';
      case MessageType.audio: return '🎤 Voice message';
      case MessageType.file: return '📎 ${fileName ?? 'File'}';
      case MessageType.link: return '🔗 ${content ?? 'Link'}';
    }
  }
}
