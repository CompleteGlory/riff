// Chat data models — Conversation, Message, ChatParticipant
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
        lastSeen: j['last_seen'] != null
            ? DateTime.tryParse(j['last_seen'] as String)
            : null,
      );

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
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final List<ChatParticipant> participants;
  final ConversationOtherUser? otherUser;
  ChatMessage? latestMessage;
  int unreadCount;

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
        lastMessageAt: j['last_message_at'] != null
            ? DateTime.tryParse(j['last_message_at'] as String)
            : null,
        createdAt: DateTime.tryParse(j['created_at'] as String) ?? DateTime.now(),
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
        createdAt: DateTime.tryParse(j['created_at'] as String) ?? DateTime.now(),
        sender: j['sender'] != null
            ? MessageSender.fromJson(j['sender'] as Map<String, dynamic>)
            : null,
        status: MessageStatusX.fromString(j['status'] as String?),
      );

  ChatMessage withStatus(MessageStatus s) => ChatMessage(
        id: id,
        conversationId: conversationId,
        type: type,
        content: content,
        mediaUrl: mediaUrl,
        fileName: fileName,
        duration: duration,
        isDeleted: isDeleted,
        createdAt: createdAt,
        sender: sender,
        status: s,
      );

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
