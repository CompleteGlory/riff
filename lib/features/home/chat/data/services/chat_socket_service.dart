import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:riff/core/networks/api_constants.dart';
import '../models/chat_models.dart';

class ChatSocketService {
  io.Socket? _socket;

  // Tracks the conversation the user is actively viewing so HomeLayout can
  // suppress unread-count increments for messages in that conversation.
  String? _currentConversationId;
  String? get currentConversationId => _currentConversationId;

  final _messageController   = StreamController<ChatMessage>.broadcast();
  final _typingController    = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptCtrl     = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController  = StreamController<Map<String, dynamic>>.broadcast();
  final _msgStatusCtrl       = StreamController<Map<String, dynamic>>.broadcast();
  final _convDeletedCtrl     = StreamController<String>.broadcast();

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

  void connect(String token) {
    if (_socket?.connected == true) return;
    _socket = io.io(
      '${ApiConstants.apiBASEURL}/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

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

  void joinConversation(String conversationId) {
    _currentConversationId = conversationId;
    _socket?.emit('join_conversation', {'conversation_id': conversationId});
  }

  void leaveConversation(String conversationId) {
    if (_currentConversationId == conversationId) _currentConversationId = null;
    _socket?.emit('leave_conversation', {'conversation_id': conversationId});
  }

  void sendTextMessage(String conversationId, String text) {
    _socket?.emit('send_message', {
      'conversation_id': conversationId,
      'type': 'text',
      'content': text,
    });
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

  void disconnect() {
    _currentConversationId = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;

  void dispose() {
    _messageController.close();
    _typingController.close();
    _readReceiptCtrl.close();
    _msgStatusCtrl.close();
    _presenceController.close();
    _convDeletedCtrl.close();
    disconnect();
  }
}
