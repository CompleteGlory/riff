import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/chat_models.dart';
import '../../data/repos/chat_repo.dart';
import '../../data/services/chat_socket_service.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepo _repo;
  final ChatSocketService _socket;
  StreamSubscription<ChatMessage>? _msgSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  StreamSubscription<Map<String, dynamic>>? _readSub;
  StreamSubscription<Map<String, dynamic>>? _statusSub;
  StreamSubscription<Map<String, dynamic>>? _presenceSub;
  StreamSubscription<String>? _convDeletedSub;
  String? _conversationId;
  String? _otherUserId;

  ChatCubit(this._repo, this._socket) : super(ChatInitial());

  Future<void> open(Conversation conversation) async {
    _conversationId = conversation.id;
    _otherUserId = conversation.otherUser?.id;
    emit(ChatLoading());
    try {
      // API returns messages newest-first; keep that order for reverse ListView
      final msgs = await _repo.getMessages(conversation.id);
      if (isClosed) return;
      // API returns oldest-first; reverse so newest is at index 0
      // → with reverse:true ListView, index 0 renders at the bottom = newest visible
      emit(ChatLoaded(
        conversation: conversation,
        messages: msgs.reversed.toList(),
        hasMore: msgs.length == 30,
      ));
      _socket.joinConversation(conversation.id);
      // Tell the backend we've read these messages
      _socket.markAsRead(conversation.id);
      _listenSocket();
    } catch (e) {
      if (!isClosed) emit(ChatError(e.toString()));
    }
  }

  void _listenSocket() {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _statusSub?.cancel();
    _presenceSub?.cancel();
    _convDeletedSub?.cancel();

    // New incoming message — prepend (newest at index 0)
    _msgSub = _socket.onMessage.listen((msg) {
      if (msg.conversationId != _conversationId) return;
      final cur = state;
      if (cur is! ChatLoaded || isClosed) return;
      // Deduplicate: the server now echoes to both the conversation room AND
      // the sender's personal room, so the sender receives two copies of their
      // own message. Drop it if we already have a message with the same ID.
      if (cur.messages.any((m) => m.id == msg.id)) return;
      emit(cur.copyWith(messages: [msg, ...cur.messages]));
      // Auto-mark as read since we're in the conversation
      _socket.markAsRead(_conversationId!);
    });

    _typingSub = _socket.onTyping.listen((data) {
      final convId = data['conversation_id'] as String?;
      if (convId != _conversationId) return;
      final userId = data['user_id'] as String?;
      final typing = data['typing'] as bool? ?? false;
      if (userId == null) return;
      final cur = state;
      if (cur is! ChatLoaded || isClosed) return;
      final updated = Map<String, bool>.from(cur.typingUsers)..[userId] = typing;
      emit(cur.copyWith(typingUsers: updated));
    });

    // Legacy read-receipt event (kept for compatibility)
    _readSub = _socket.onRead.listen((data) {
      final convId = data['conversation_id'] as String?;
      if (convId != _conversationId) return;
      final cur = state;
      if (cur is! ChatLoaded || isClosed) return;
      final updated = cur.messages.map((m) {
        if (m.status == MessageStatus.read) return m;
        return m.withStatus(MessageStatus.read);
      }).toList();
      emit(cur.copyWith(messages: updated));
    });

    // Unified status updates: delivered (recipient online) and read (recipient opened chat)
    // Payload: { conversation_id, status: 'delivered'|'read', message_id? }
    // If message_id is present → update that specific message only.
    // If absent → upgrade ALL messages in this conversation to that status.
    _statusSub = _socket.onMessageStatus.listen((data) {
      final convId = data['conversation_id'] as String?;
      if (convId != _conversationId) return;
      final cur = state;
      if (cur is! ChatLoaded || isClosed) return;

      final newStatus = MessageStatusX.fromString(data['status'] as String?);
      final msgId = data['message_id'] as String?;

      final updated = cur.messages.map((m) {
        if (msgId != null && m.id != msgId) return m;
        // Only upgrade (sent→delivered→read), never downgrade
        if (m.status.index >= newStatus.index) return m;
        return m.withStatus(newStatus);
      }).toList();

      emit(cur.copyWith(messages: updated));
    });

    // Conversation deleted by either participant — navigate away
    _convDeletedSub = _socket.onConversationDeleted.listen((convId) {
      if (convId != _conversationId) return;
      if (!isClosed) emit(ChatDeleted());
    });

    // Presence — update online / last-seen in header
    _presenceSub = _socket.onPresence.listen((data) {
      final userId = data['user_id'] as String?;
      if (userId == null || userId != _otherUserId) return;
      final cur = state;
      if (cur is! ChatLoaded || isClosed) return;
      final online = data['is_online'] as bool? ?? false;
      final lastSeenStr = data['last_seen'] as String?;
      final lastSeen = lastSeenStr != null ? DateTime.tryParse(lastSeenStr) : null;
      emit(cur.copyWith(
        conversation: cur.conversation.withOtherUserPresence(online, lastSeen: lastSeen),
      ));
    });
  }

  Future<void> loadMore() async {
    final cur = state;
    if (cur is! ChatLoaded || !cur.hasMore || _conversationId == null) return;
    try {
      // oldest message is at the end of the list (index last)
      final oldestId = cur.messages.isNotEmpty ? cur.messages.last.id : null;
      final older = await _repo.getMessages(_conversationId!, beforeId: oldestId);
      if (isClosed) return;
      // Reverse so older-newest is first, then append to end of current list
      // (end of list = top of reverse ListView = scroll-up history)
      emit(cur.copyWith(
        messages: [...cur.messages, ...older.reversed],
        hasMore: older.length == 30,
      ));
    } catch (_) {}
  }

  void sendText(String text) {
    if (_conversationId == null) return;
    _socket.sendTextMessage(_conversationId!, text);
  }

  Future<void> sendMedia(
    String filePath,
    String fileName,
    String mimeType, {
    int? duration,
  }) async {
    if (_conversationId == null) return;
    final cur = state;
    if (cur is! ChatLoaded) return;

    // Determine media type for the pending bubble
    String mediaType = 'file';
    if (mimeType.startsWith('image/')) {
      mediaType = 'image';
    } else if (mimeType.startsWith('video/')) {
      mediaType = 'video';
    }
    else if (mimeType.startsWith('audio/')) {
      mediaType = 'audio';
    }

    emit(cur.copyWith(isSending: true, sendingMediaType: mediaType));
    try {
      final msg = await _repo.uploadMedia(
        _conversationId!, filePath, fileName, mimeType,
        duration: duration,
      );
      if (isClosed) return;
      final nowCur = state as ChatLoaded;
      // The socket broadcast can arrive before the HTTP response returns,
      // meaning onMessage may have already added this message to the list.
      // Check by ID to avoid the duplicate that causes the double-bubble bug.
      final alreadyAdded = nowCur.messages.any((m) => m.id == msg.id);
      emit(nowCur.copyWith(
        messages: alreadyAdded ? nowCur.messages : [msg, ...nowCur.messages],
        isSending: false,
        sendingMediaType: null,
      ));
    } catch (_) {
      if (!isClosed && state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(
          isSending: false,
          sendingMediaType: null,
        ));
      }
    }
  }

  void startTyping() => _socket.sendTypingStart(_conversationId ?? '');
  void stopTyping()  => _socket.sendTypingStop(_conversationId ?? '');

  /// Accept the incoming chat request — updates isRequest to false in state.
  Future<void> acceptRequest() async {
    final cur = state;
    if (cur is! ChatLoaded || _conversationId == null) return;
    await _repo.acceptRequest(_conversationId!);
    if (isClosed) return;
    final c = cur.conversation;
    final updated = Conversation(
      id: c.id,
      type: c.type,
      name: c.name,
      description: c.description,
      imageUrl: c.imageUrl,
      isRequest: false,
      lastMessageAt: c.lastMessageAt,
      createdAt: c.createdAt,
      participants: c.participants,
      otherUser: c.otherUser,
      latestMessage: c.latestMessage,
      unreadCount: c.unreadCount,
    );
    emit(cur.copyWith(conversation: updated));
  }

  /// Decline the incoming chat request — caller is responsible for navigation.
  Future<void> declineRequest() async {
    if (_conversationId == null) return;
    await _repo.declineRequest(_conversationId!);
  }

  Future<void> deleteMessage(String messageId) async {
    final cur = state;
    if (cur is! ChatLoaded || _conversationId == null) return;
    final updated = cur.messages.map((m) {
      if (m.id != messageId) return m;
      return ChatMessage(
        id: m.id,
        conversationId: m.conversationId,
        type: m.type,
        content: m.content,
        mediaUrl: m.mediaUrl,
        fileName: m.fileName,
        duration: m.duration,
        isDeleted: true,
        createdAt: m.createdAt,
        sender: m.sender,
      );
    }).toList();
    if (!isClosed) emit(cur.copyWith(messages: updated));
    try { await _repo.deleteMessage(_conversationId!, messageId); } catch (_) {}
  }

  /// Delete the conversation for all participants.
  Future<void> deleteConversation() async {
    if (_conversationId == null) return;
    try {
      await _repo.deleteConversation(_conversationId!);
      if (!isClosed) emit(ChatDeleted());
    } catch (_) {}
  }

  @override
  Future<void> close() {
    if (_conversationId != null) _socket.leaveConversation(_conversationId!);
    _msgSub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _statusSub?.cancel();
    _presenceSub?.cancel();
    _convDeletedSub?.cancel();
    return super.close();
  }
}
