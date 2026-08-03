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

  /// True when [messages] came out of the offline cache rather than the API,
  /// so the screen can say so instead of presenting a stale chunk of history as
  /// the live conversation.
  final bool isFromCache;

  /// The message the composer is currently rewriting, or null when it is
  /// composing a new one. Kept in state rather than in the input bar so that
  /// tapping "Edit" in the long-press sheet — which happens well away from the
  /// composer — is all it takes to put it into edit mode.
  final ChatMessage? editingMessage;

  /// The message the composer is quoting, or null when it isn't.
  ///
  /// Mutually exclusive with [editingMessage] — you are either rewriting a
  /// message or answering one, never both. The cubit enforces that, so the
  /// composer never has to reconcile two banners fighting for the same space.
  final ChatMessage? replyingTo;

  ChatLoaded({
    required this.conversation,
    required this.messages,
    this.hasMore = false,
    this.typingUsers = const {},
    this.isSending = false,
    this.isBlocked = false,
    this.sendingMediaType,
    this.isFromCache = false,
    this.editingMessage,
    this.replyingTo,
  });

  ChatLoaded copyWith({
    Conversation? conversation,
    List<ChatMessage>? messages,
    bool? hasMore,
    Map<String, bool>? typingUsers,
    bool? isSending,
    bool? isBlocked,
    bool? isFromCache,
    Object? sendingMediaType = _sentinel,
    Object? editingMessage = _sentinel,
    Object? replyingTo = _sentinel,
  }) => ChatLoaded(
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    hasMore: hasMore ?? this.hasMore,
    typingUsers: typingUsers ?? this.typingUsers,
    isSending: isSending ?? this.isSending,
    isBlocked: isBlocked ?? this.isBlocked,
    isFromCache: isFromCache ?? this.isFromCache,
    sendingMediaType: sendingMediaType == _sentinel
        ? this.sendingMediaType
        : sendingMediaType as String?,
    editingMessage: editingMessage == _sentinel
        ? this.editingMessage
        : editingMessage as ChatMessage?,
    replyingTo: replyingTo == _sentinel
        ? this.replyingTo
        : replyingTo as ChatMessage?,
  );
}

// Sentinel so copyWith can clear sendingMediaType to null
const _sentinel = Object();
