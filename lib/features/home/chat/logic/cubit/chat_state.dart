part of 'chat_cubit.dart';

abstract class ChatState {}

class ChatInitial  extends ChatState {}
class ChatLoading  extends ChatState {}
class ChatError    extends ChatState { final String message; ChatError(this.message); }
/// Emitted when the conversation was deleted (by self or the other participant).
class ChatDeleted  extends ChatState {}

class ChatLoaded extends ChatState {
  final Conversation conversation;
  final List<ChatMessage> messages;
  final bool hasMore;
  final Map<String, bool> typingUsers; // userId → isTyping
  final bool isSending;
  final bool isBlocked;
  /// Type of media currently being uploaded ('image' | 'video' | 'audio') — null = not uploading
  final String? sendingMediaType;

  ChatLoaded({
    required this.conversation,
    required this.messages,
    this.hasMore = false,
    this.typingUsers = const {},
    this.isSending = false,
    this.isBlocked = false,
    this.sendingMediaType,
  });

  ChatLoaded copyWith({
    Conversation? conversation,
    List<ChatMessage>? messages,
    bool? hasMore,
    Map<String, bool>? typingUsers,
    bool? isSending,
    bool? isBlocked,
    Object? sendingMediaType = _sentinel,
  }) => ChatLoaded(
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    hasMore: hasMore ?? this.hasMore,
    typingUsers: typingUsers ?? this.typingUsers,
    isSending: isSending ?? this.isSending,
    isBlocked: isBlocked ?? this.isBlocked,
    sendingMediaType: sendingMediaType == _sentinel
        ? this.sendingMediaType
        : sendingMediaType as String?,
  );
}

// Sentinel so copyWith can clear sendingMediaType to null
const _sentinel = Object();
