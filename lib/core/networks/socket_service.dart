import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:riff/core/services/session_manager.dart';
import 'api_constants.dart';

/// Socket for the `/notifications` namespace.
///
/// Like the chat gateway, this handshake authenticates with the access token
/// and is never re-authenticated, so it has to be re-established whenever the
/// token is refreshed — otherwise realtime notifications quietly stop and only
/// the 30-second poll keeps the badge alive.
class SocketService {
  io.Socket? _socket;

  String? _connectedWithToken;
  StreamSubscription<String>? _tokenRefreshSub;

  /// Handlers registered by callers, replayed onto every new socket so a
  /// reconnect doesn't silently lose them.
  final Map<String, Function(dynamic)> _handlers = {};

  bool get isConnected => _socket?.connected ?? false;

  /// Connects with a valid (refreshed if needed) access token.
  Future<bool> ensureConnected() async {
    final token = await SessionManager.instance.validAccessToken();
    if (token == null || token.isEmpty) return false;
    if (isConnected && _connectedWithToken == token) return true;
    connect(token);
    return true;
  }

  void connect(String token) {
    if (_socket?.connected == true && _connectedWithToken == token) return;

    _teardownSocket();
    _listenForTokenRefresh();

    _connectedWithToken = token;
    _socket = io.io(
      '${ApiConstants.apiBASEURL}/notifications',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
    _handlers.forEach((event, handler) => _socket!.on(event, handler));
    _socket!.connect();
  }

  void _listenForTokenRefresh() {
    _tokenRefreshSub ??=
        SessionManager.instance.onAccessTokenRefreshed.listen((token) {
      if (_connectedWithToken == token) return;
      connect(token);
    });
  }

  void on(String event, Function(dynamic) handler) {
    _handlers[event] = handler;
    _socket?.on(event, handler);
  }

  void off(String event) {
    _handlers.remove(event);
    _socket?.off(event);
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

  void disconnect() {
    _connectedWithToken = null;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _teardownSocket();
  }
}
