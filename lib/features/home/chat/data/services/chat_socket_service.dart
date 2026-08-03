import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/services/session_manager.dart';
import '../models/chat_models.dart';

class ChatSocketService {
  io.Socket? _socket;

  // Tracks the conversation the user is actively viewing so HomeLayout can
  // suppress unread-count increments for messages in that conversation.
  String? _currentConversationId;
  String? get currentConversationId => _currentConversationId;

  /// The token the live socket handshook with, so a refresh that produces the
  /// same token doesn't cause a pointless reconnect.
  String? _connectedWithToken;

  StreamSubscription<String>? _tokenRefreshSub;
  Future<bool>? _inFlightConnect;

  final _messageController   = StreamController<ChatMessage>.broadcast();
  final _typingController    = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptCtrl     = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController  = StreamController<Map<String, dynamic>>.broadcast();
  final _msgStatusCtrl       = StreamController<Map<String, dynamic>>.broadcast();
  final _convDeletedCtrl     = StreamController<String>.broadcast();
  final _connectionCtrl      = StreamController<bool>.broadcast();
  final _msgDeletedCtrl      = StreamController<Map<String, dynamic>>.broadcast();
  final _msgEditedCtrl       = StreamController<ChatMessage>.broadcast();
  final _msgReactionCtrl     = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ChatMessage> get onMessage                => _messageController.stream;
  Stream<Map<String, dynamic>> get onTyping        => _typingController.stream;
  /// Legacy read-receipt stream (kept for compatibility).
  Stream<Map<String, dynamic>> get onRead          => _readReceiptCtrl.stream;
  /// Unified status stream — payload: {conversation_id, status, message_id?}
  /// status: 'delivered' | 'read'
  Stream<Map<String, dynamic>> get onMessageStatus => _msgStatusCtrl.stream;
  /// Payload: {user_id, is_online, last_seen?}
  Stream<Map<String, dynamic>> get onPresence      => _presenceController.stream;
  /// Emits the conversation_id of any conversation deleted by any participant.
  Stream<String> get onConversationDeleted         => _convDeletedCtrl.stream;
  /// Emits true on connect, false on disconnect / handshake rejection.
  Stream<bool> get onConnectionChanged             => _connectionCtrl.stream;

  /// A message was deleted for everyone. Payload:
  /// `{conversation_id, message_id, last_message_at, latest_message}` — the
  /// last two describe where the conversation now sorts and what its row
  /// should preview, since deleting the newest message moves it *down* the
  /// chat list rather than to the top.
  Stream<Map<String, dynamic>> get onMessageDeleted => _msgDeletedCtrl.stream;

  /// A message's text was rewritten. Carries the whole updated message.
  Stream<ChatMessage> get onMessageEdited          => _msgEditedCtrl.stream;

  /// A message's reactions changed. Payload:
  /// `{conversation_id, message_id, reactions, actor_id}` — always the full
  /// list, never a delta.
  Stream<Map<String, dynamic>> get onMessageReaction => _msgReactionCtrl.stream;

  bool get isConnected => _socket?.connected ?? false;

  // ── Connection ────────────────────────────────────────────────────────────

  /// Connects (or reconnects) with a **valid** access token, refreshing an
  /// expired one first.
  ///
  /// The gateway verifies the access token during the handshake and drops the
  /// client outright when it fails (`ChatGateway.handleConnection`). Access
  /// tokens only live 15 minutes, so anything resuming after a pause — most of
  /// all a push-notification tap — used to hand the gateway an expired token
  /// and get silently disconnected. HTTP still worked (its interceptor
  /// refreshes on 401), so messages loaded fine but every `send_message` emit
  /// went nowhere: the "I have to restart the app before I can reply" bug.
  ///
  /// Returns true once the socket reports connected.
  Future<bool> ensureConnected() {
    return _inFlightConnect ??= _ensureConnected().whenComplete(() {
      _inFlightConnect = null;
    });
  }

  Future<bool> _ensureConnected() async {
    final token = await SessionManager.instance.validAccessToken();
    if (token == null || token.isEmpty) return false;

    if (isConnected && _connectedWithToken == token) return true;

    connect(token);
    return _awaitConnection();
  }

  Future<bool> _awaitConnection({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (isConnected) return true;
    final deadline = DateTime.now().add(timeout);
    while (!isConnected) {
      if (!DateTime.now().isBefore(deadline)) return false;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return true;
  }

  /// Opens a socket with [token], replacing any existing one.
  ///
  /// The previous socket is disposed first. `io.io()` multiplexes on the URI
  /// and hands back the *same* Socket for a namespace it already knows, so the
  /// old code — which called `io.io()` again on every app resume without
  /// disposing — kept stacking duplicate `on(...)` handlers on one socket, and
  /// every incoming message was delivered several times over.
  void connect(String token) {
    if (_socket?.connected == true && _connectedWithToken == token) return;

    _teardownSocket();
    _listenForTokenRefresh();

    _connectedWithToken = token;
    _socket = io.io(
      '${ApiConstants.apiBASEURL}/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      _emitConnectionState(true);
      // Re-join the open conversation: a reconnect starts in no rooms, so
      // without this the user sits in a chat that silently stops updating.
      final convId = _currentConversationId;
      if (convId != null) {
        _socket?.emit('join_conversation', {'conversation_id': convId});
      }
    });

    _socket!.onDisconnect((_) => _emitConnectionState(false));

    _socket!.onConnectError((err) {
      debugPrint('ChatSocketService: connect error — $err');
      _emitConnectionState(false);
    });

    _socket!.on('message_received', (data) {
      try {
        final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data as Map));
        _messageController.add(msg);
      } catch (_) {}
    });

    _socket!.on('user_typing', (data) {
      _typingController.add(Map<String, dynamic>.from(data as Map));
    });

    _socket!.on('message_read', (data) {
      try {
        _readReceiptCtrl.add(Map<String, dynamic>.from(data as Map));
      } catch (_) {}
    });

    _socket!.on('message_status', (data) {
      try {
        _msgStatusCtrl.add(Map<String, dynamic>.from(data as Map));
      } catch (_) {}
    });

    _socket!.on('message_deleted', (data) {
      try {
        _msgDeletedCtrl.add(Map<String, dynamic>.from(data as Map));
      } catch (_) {}
    });

    _socket!.on('message_edited', (data) {
      try {
        _msgEditedCtrl.add(
            ChatMessage.fromJson(Map<String, dynamic>.from(data as Map)));
      } catch (_) {}
    });

    _socket!.on('message_reaction', (data) {
      try {
        _msgReactionCtrl.add(Map<String, dynamic>.from(data as Map));
      } catch (_) {}
    });

    _socket!.on('conversation_deleted', (data) {
      try {
        final convId = (data as Map)['conversation_id'] as String?;
        if (convId != null) _convDeletedCtrl.add(convId);
      } catch (_) {}
    });

    _socket!.on('user_online', (data) {
      try {
        _presenceController.add({
          ...Map<String, dynamic>.from(data as Map),
          'is_online': true,
        });
      } catch (_) {}
    });

    _socket!.on('user_offline', (data) {
      try {
        _presenceController.add({
          ...Map<String, dynamic>.from(data as Map),
          'is_online': false,
        });
      } catch (_) {}
    });

    _socket!.connect();
  }

  /// Reconnect with the new token whenever the session refreshes, so a socket
  /// authenticated with a now-expired token doesn't stay dead until restart.
  void _listenForTokenRefresh() {
    _tokenRefreshSub ??=
        SessionManager.instance.onAccessTokenRefreshed.listen((token) {
      if (_connectedWithToken == token) return;
      connect(token);
    });
  }

  void _emitConnectionState(bool connected) {
    if (!_connectionCtrl.isClosed) _connectionCtrl.add(connected);
  }

  void _teardownSocket() {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    try {
      socket.clearListeners();
      socket.disconnect();
      socket.dispose();
    } catch (_) {}
  }

  // ── Conversation rooms ────────────────────────────────────────────────────

  void joinConversation(String conversationId) {
    _currentConversationId = conversationId;
    _socket?.emit('join_conversation', {'conversation_id': conversationId});
  }

  void leaveConversation(String conversationId) {
    if (_currentConversationId == conversationId) _currentConversationId = null;
    _socket?.emit('leave_conversation', {'conversation_id': conversationId});
  }

  // ── Emits ─────────────────────────────────────────────────────────────────

  /// Sends a text message, reconnecting first if the socket is down.
  ///
  /// [clientId] is echoed back by the gateway on the saved message, so the
  /// optimistic bubble the sender is already looking at can be replaced by the
  /// real one rather than duplicated next to it.
  ///
  /// Returns false when the message could not be handed to a live socket, so
  /// the caller can tell the user instead of leaving them staring at a message
  /// that silently never sent.
  Future<bool> sendTextMessage(
    String conversationId,
    String text, {
    String? clientId,
    String? replyToId,
  }) async {
    if (!await ensureConnected()) return false;
    _socket?.emit('send_message', {
      'conversation_id': conversationId,
      'type': 'text',
      'content': text,
      if (clientId != null) 'client_id': clientId,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
    return true;
  }

  /// Notify backend that current user read all messages in this conversation.
  void markAsRead(String conversationId) {
    _socket?.emit('mark_read', {'conversation_id': conversationId});
  }

  void sendTypingStart(String conversationId) {
    _socket?.emit('typing_start', {'conversation_id': conversationId});
  }

  void sendTypingStop(String conversationId) {
    _socket?.emit('typing_stop', {'conversation_id': conversationId});
  }

  // ── Teardown ──────────────────────────────────────────────────────────────

  void disconnect() {
    _currentConversationId = null;
    _connectedWithToken = null;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _teardownSocket();
    _emitConnectionState(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _readReceiptCtrl.close();
    _msgStatusCtrl.close();
    _presenceController.close();
    _convDeletedCtrl.close();
    _connectionCtrl.close();
    _msgDeletedCtrl.close();
    _msgEditedCtrl.close();
    _msgReactionCtrl.close();
  }
}
