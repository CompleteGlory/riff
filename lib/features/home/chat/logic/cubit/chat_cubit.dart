import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/cache/cache_keys.dart';
import 'package:riff/core/cache/offline_cache.dart';
import 'package:riff/core/helpers/app_date_time.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/connectivity_service.dart';
import '../../data/models/chat_models.dart';
import '../../data/repos/chat_repo.dart';
import '../../data/services/chat_socket_service.dart';

part 'chat_state.dart';

/// Everything needed to send one message again after it failed.
class _OutboundMessage {
  const _OutboundMessage.text(this.text)
      : filePath = null,
        fileName = null,
        mimeType = null,
        duration = null;

  const _OutboundMessage.media({
    required String this.filePath,
    required String this.fileName,
    required String this.mimeType,
    this.duration,
  }) : text = null;

  final String? text;
  final String? filePath;
  final String? fileName;
  final String? mimeType;
  final int? duration;

  bool get isText => text != null;
}

class ChatCubit extends Cubit<ChatState> {
  final ChatRepo _repo;
  final ChatSocketService _socket;
  final OfflineCache _cache;
  StreamSubscription<ChatMessage>? _msgSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  StreamSubscription<Map<String, dynamic>>? _readSub;
  StreamSubscription<Map<String, dynamic>>? _statusSub;
  StreamSubscription<Map<String, dynamic>>? _presenceSub;
  StreamSubscription<String>? _convDeletedSub;
  StreamSubscription<bool>? _connectivitySub;
  String? _conversationId;
  String? _otherUserId;

  /// The signed-in user, as the sender of an optimistic bubble. Loaded once per
  /// open() so a pending message shows the right avatar and sits on the right
  /// side of the screen before the server has ever seen it.
  MessageSender? _me;

  /// Sends still waiting for the server, keyed by client id, so a failure can
  /// be retried without asking the user to type or re-record anything.
  final Map<String, _OutboundMessage> _outbound = {};
  final Map<String, Timer> _pendingTimers = {};
  int _clientSeq = 0;

  /// How long an unacknowledged send waits before it is called failed.
  ///
  /// Socket emits are fire-and-forget: `socket.emit` succeeding only means the
  /// bytes left the device, not that the gateway stored anything. Without a
  /// deadline a message sent as the connection dies would sit dimmed forever.
  @visibleForTesting
  static Duration pendingTimeout = const Duration(seconds: 20);

  ChatCubit(this._repo, this._socket, {OfflineCache? cache})
      : _cache = cache ?? OfflineCache.instance,
        super(ChatInitial());

  Future<void> open(Conversation conversation) async {
    _conversationId = conversation.id;
    _otherUserId = conversation.otherUser?.id;
    await _loadMe();

    // Paint whatever was cached first. On a slow or dead connection this is the
    // difference between a spinner and the conversation the user was reading a
    // minute ago; on a fast one it is replaced before it can be noticed.
    final cached = await _readCachedMessages(conversation.id);
    if (isClosed) return;
    if (cached != null && cached.isNotEmpty) {
      emit(ChatLoaded(
        conversation: conversation,
        messages: cached,
        hasMore: cached.length >= CacheKeys.conversationMessagesLimit,
        isFromCache: true,
      ));
    } else {
      emit(ChatLoading());
    }

    _listenSocket();
    _listenConnectivity();

    await _fetchMessages(conversation);
  }

  /// Loads the live message list, falling back to whatever is already on screen.
  Future<void> _fetchMessages(Conversation conversation) async {
    try {
      final msgs = await _repo.getMessages(conversation.id);
      if (isClosed) return;
      // API returns oldest-first; reverse so newest is at index 0
      // → with reverse:true ListView, index 0 renders at the bottom = newest visible
      final ordered = msgs.reversed.toList();
      final cur = state;
      emit(ChatLoaded(
        conversation: conversation,
        messages: [
          // Keep anything the user sent while the fetch was in flight (or while
          // offline) — it isn't on the server yet, so the response won't have it.
          if (cur is ChatLoaded) ...cur.messages.where(_isUnsent),
          ...ordered,
        ],
        hasMore: msgs.length == 30,
      ));
      unawaited(_cacheMessages());

      // Make sure the socket is actually alive before joining the room. Opening
      // a chat straight from a push notification means the app has been idle
      // long enough for the access token to expire, and the gateway rejects the
      // handshake outright when it has — leaving a screen that loads over HTTP
      // but can neither send nor receive.
      await _socket.ensureConnected();
      if (isClosed) return;
      _socket.joinConversation(conversation.id);
      // Tell the backend we've read these messages
      _socket.markAsRead(conversation.id);
    } catch (e) {
      if (isClosed) return;
      // A cached conversation is already on screen — leaving it there beats
      // replacing real history with an error page.
      if (state is ChatLoaded) return;
      emit(ChatError(e.toString()));
    }
  }

  bool _isUnsent(ChatMessage m) => m.isPending || m.hasFailed;

  Future<void> _loadMe() async {
    if (_me != null) return;
    final id =
        await SharedPrefHelper.getString(SharedPrefKeys.userId) as String? ?? '';
    if (id.isEmpty) return;
    final first =
        await SharedPrefHelper.getString(SharedPrefKeys.firstName) as String? ??
            '';
    final last =
        await SharedPrefHelper.getString(SharedPrefKeys.lastName) as String? ??
            '';
    final image = await SharedPrefHelper.getString(
            SharedPrefKeys.userProfileImage) as String? ??
        '';
    _me = MessageSender(
      id: id,
      fullName: '$first $last'.trim(),
      profileImageUrl: image.isEmpty ? null : image,
    );
  }

  // ── Offline cache ─────────────────────────────────────────────────────────

  Future<List<ChatMessage>?> _readCachedMessages(String conversationId) async {
    final raw = await _cache.readList(
      CacheKeys.conversationMessages(conversationId),
    );
    if (raw == null) return null;
    try {
      return raw.map(ChatMessage.fromJson).toList();
    } catch (e) {
      debugPrint('ChatCubit: cached messages unreadable — $e');
      return null;
    }
  }

  Future<void> _cacheMessages() async {
    final cur = state;
    final convId = _conversationId;
    if (cur is! ChatLoaded || convId == null) return;
    // Only confirmed messages: an optimistic bubble restored from cache would
    // claim the user said something they may never have managed to send.
    final confirmed =
        cur.messages.where((m) => m.delivery == MessageDelivery.complete);
    await _cache.writeList(
      CacheKeys.conversationMessages(convId),
      confirmed.map((m) => m.toJson()).toList(),
      limit: CacheKeys.conversationMessagesLimit,
    );
  }

  /// Re-fetches the conversation as soon as connectivity returns, so a chat
  /// left open on a dead connection catches up on its own.
  void _listenConnectivity() {
    _connectivitySub?.cancel();
    _connectivitySub =
        ConnectivityService.instance.onStatusChanged.listen((online) {
      if (!online || isClosed) return;
      final cur = state;
      if (cur is! ChatLoaded) return;
      unawaited(_fetchMessages(cur.conversation));
    });
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

      // The sender's own message comes back as a real one. Swap it in place of
      // the optimistic bubble instead of adding a second copy underneath it.
      final optimisticIndex = _indexOfOptimisticMatch(cur.messages, msg);
      if (optimisticIndex != -1) {
        final replaced = List<ChatMessage>.from(cur.messages);
        _settle(replaced[optimisticIndex].clientId);
        replaced[optimisticIndex] = msg;
        emit(cur.copyWith(messages: replaced));
        unawaited(_cacheMessages());
        return;
      }

      // Deduplicate: the server echoes to both the conversation room AND the
      // sender's personal room, so the sender receives two copies of their own
      // message. Drop it if we already have a message with the same ID.
      if (cur.messages.any((m) => m.id == msg.id)) return;
      emit(cur.copyWith(messages: [msg, ...cur.messages]));
      unawaited(_cacheMessages());
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
        if (m.status == MessageStatus.read || _isUnsent(m)) return m;
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
        // A message that hasn't reached the server can't have been read.
        if (_isUnsent(m)) return m;
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
      final lastSeen = parseServerDateTime(lastSeenStr);
      emit(cur.copyWith(
        conversation: cur.conversation.withOtherUserPresence(online, lastSeen: lastSeen),
      ));
    });
  }

  /// Finds the optimistic bubble [incoming] is the confirmed version of.
  ///
  /// The gateway echoes `client_id` back, which is exact. The fallback matches
  /// on sender + type + payload so the app still reconciles correctly against
  /// an API build that predates the echo — without it every message the user
  /// sent would appear twice.
  ///
  /// The gateway only discloses `client_id` on the copy it sends back to the
  /// sender, so a recipient can never match one of their own bubbles against
  /// someone else's message.
  int _indexOfOptimisticMatch(List<ChatMessage> messages, ChatMessage incoming) {
    final clientId = incoming.clientId;
    if (clientId != null && clientId.isNotEmpty) {
      return messages.indexWhere((m) => m.clientId == clientId);
    }
    final myId = _me?.id;
    if (myId == null || incoming.sender?.id != myId) return -1;
    return messages.indexWhere((m) {
      if (!m.isPending || m.type != incoming.type) return false;
      return m.type == MessageType.text
          ? m.content == incoming.content
          : m.fileName == incoming.fileName;
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

  // ── Sending ───────────────────────────────────────────────────────────────

  String _newClientId() =>
      'local-${DateTime.now().microsecondsSinceEpoch}-${_clientSeq++}';

  /// Sends a text message.
  ///
  /// The bubble appears immediately, dimmed, and either firms up when the
  /// server echoes it back or turns into a retryable failure. Returns false
  /// when the message could not even be handed to a live socket.
  Future<bool> sendText(String text) async {
    final convId = _conversationId;
    final cur = state;
    if (convId == null || cur is! ChatLoaded) return false;

    final clientId = _newClientId();
    _outbound[clientId] = _OutboundMessage.text(text);
    emit(cur.copyWith(messages: [
      ChatMessage(
        id: clientId,
        conversationId: convId,
        type: MessageType.text,
        content: text,
        isDeleted: false,
        createdAt: DateTime.now(),
        sender: _me,
        clientId: clientId,
        delivery: MessageDelivery.pending,
      ),
      ...cur.messages,
    ]));

    return _dispatchText(clientId, convId, text);
  }

  Future<bool> _dispatchText(
    String clientId,
    String conversationId,
    String text,
  ) async {
    final ok =
        await _socket.sendTextMessage(conversationId, text, clientId: clientId);
    if (isClosed) return ok;
    if (!ok) {
      _markFailed(clientId);
      return false;
    }
    _armPendingTimeout(clientId);
    return true;
  }

  Future<void> sendMedia(
    String filePath,
    String fileName,
    String mimeType, {
    int? duration,
  }) async {
    final convId = _conversationId;
    final cur = state;
    if (convId == null || cur is! ChatLoaded) return;

    final clientId = _newClientId();
    _outbound[clientId] = _OutboundMessage.media(
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType,
      duration: duration,
    );

    emit(cur.copyWith(messages: [
      ChatMessage(
        id: clientId,
        conversationId: convId,
        type: _mediaTypeFor(mimeType),
        fileName: fileName,
        duration: duration,
        isDeleted: false,
        createdAt: DateTime.now(),
        sender: _me,
        clientId: clientId,
        delivery: MessageDelivery.pending,
        localMediaPath: filePath,
      ),
      ...cur.messages,
    ]));

    await _dispatchMedia(clientId, convId, _outbound[clientId]!);
  }

  Future<void> _dispatchMedia(
    String clientId,
    String conversationId,
    _OutboundMessage outbound,
  ) async {
    try {
      final msg = await _repo.uploadMedia(
        conversationId,
        outbound.filePath!,
        outbound.fileName!,
        outbound.mimeType!,
        duration: outbound.duration,
        clientId: clientId,
      );
      if (isClosed) return;
      _replaceOptimistic(clientId, msg);
    } catch (_) {
      if (!isClosed) _markFailed(clientId);
    }
  }

  MessageType _mediaTypeFor(String mimeType) {
    if (mimeType.startsWith('image/')) return MessageType.image;
    if (mimeType.startsWith('video/')) return MessageType.video;
    if (mimeType.startsWith('audio/')) return MessageType.audio;
    return MessageType.file;
  }

  /// Re-sends a message whose first attempt failed.
  Future<void> retryMessage(String clientId) async {
    final convId = _conversationId;
    final outbound = _outbound[clientId];
    final cur = state;
    if (convId == null || outbound == null || cur is! ChatLoaded) return;

    emit(cur.copyWith(
      messages: _mapByClientId(
        cur.messages,
        clientId,
        (m) => m.copyWith(delivery: MessageDelivery.pending),
      ),
    ));

    if (outbound.isText) {
      await _dispatchText(clientId, convId, outbound.text!);
    } else {
      await _dispatchMedia(clientId, convId, outbound);
    }
  }

  /// Drops a failed message the user has given up on.
  void discardMessage(String clientId) {
    final cur = state;
    if (cur is! ChatLoaded || isClosed) return;
    _settle(clientId);
    _outbound.remove(clientId);
    emit(cur.copyWith(
      messages: cur.messages.where((m) => m.clientId != clientId).toList(),
    ));
  }

  void _replaceOptimistic(String clientId, ChatMessage confirmed) {
    final cur = state;
    if (cur is! ChatLoaded || isClosed) return;
    _settle(clientId);

    if (!cur.messages.any((m) => m.clientId == clientId)) {
      // The socket broadcast beat the HTTP response and already reconciled it.
      // Adding it again is the double-bubble bug.
      if (cur.messages.any((m) => m.id == confirmed.id)) return;
      emit(cur.copyWith(messages: [confirmed, ...cur.messages]));
      unawaited(_cacheMessages());
      return;
    }

    final updated = <ChatMessage>[];
    for (final m in cur.messages) {
      if (m.clientId == clientId) {
        updated.add(confirmed);
      } else if (m.id != confirmed.id) {
        updated.add(m);
      }
      // else: the socket delivered the same message too — keep only one copy.
    }
    emit(cur.copyWith(messages: updated));
    unawaited(_cacheMessages());
  }

  void _markFailed(String clientId) {
    final cur = state;
    if (cur is! ChatLoaded || isClosed) return;
    // Only the timeout is cleared — the outbound payload has to survive, or
    // "retry" would have nothing to send and the user would be retyping.
    _cancelTimeout(clientId);
    emit(cur.copyWith(
      messages: _mapByClientId(
        cur.messages,
        clientId,
        (m) => m.copyWith(delivery: MessageDelivery.failed),
      ),
    ));
  }

  List<ChatMessage> _mapByClientId(
    List<ChatMessage> messages,
    String clientId,
    ChatMessage Function(ChatMessage) transform,
  ) =>
      messages
          .map((m) => m.clientId == clientId ? transform(m) : m)
          .toList();

  void _armPendingTimeout(String clientId) {
    _pendingTimers[clientId]?.cancel();
    _pendingTimers[clientId] = Timer(pendingTimeout, () {
      _pendingTimers.remove(clientId);
      final cur = state;
      if (cur is! ChatLoaded || isClosed) return;
      final stillPending =
          cur.messages.any((m) => m.clientId == clientId && m.isPending);
      if (stillPending) _markFailed(clientId);
    });
  }

  void _cancelTimeout(String? clientId) {
    if (clientId == null) return;
    _pendingTimers.remove(clientId)?.cancel();
  }

  /// The message is done with — confirmed or thrown away. Drop everything held
  /// for it.
  void _settle(String? clientId) {
    if (clientId == null) return;
    _cancelTimeout(clientId);
    _outbound.remove(clientId);
  }

  /// Re-establishes the socket (refreshing an expired token first) and re-joins
  /// the open conversation. Called when the screen is opened.
  Future<bool> ensureConnected() async {
    final connected = await _socket.ensureConnected();
    final convId = _conversationId;
    if (connected && convId != null) _socket.joinConversation(convId);
    return connected;
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
    final updated = cur.messages
        .map((m) => m.id == messageId ? m.copyWith(isDeleted: true) : m)
        .toList();
    if (!isClosed) emit(cur.copyWith(messages: updated));
    try { await _repo.deleteMessage(_conversationId!, messageId); } catch (_) {}
    unawaited(_cacheMessages());
  }

  /// Delete the conversation for all participants.
  Future<void> deleteConversation() async {
    if (_conversationId == null) return;
    try {
      await _repo.deleteConversation(_conversationId!);
      await _cache.remove(CacheKeys.conversationMessages(_conversationId!));
      if (!isClosed) emit(ChatDeleted());
    } catch (_) {}
  }

  @override
  Future<void> close() {
    if (_conversationId != null) _socket.leaveConversation(_conversationId!);
    for (final timer in _pendingTimers.values) {
      timer.cancel();
    }
    _pendingTimers.clear();
    _msgSub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _statusSub?.cancel();
    _presenceSub?.cancel();
    _convDeletedSub?.cancel();
    _connectivitySub?.cancel();
    return super.close();
  }
}
