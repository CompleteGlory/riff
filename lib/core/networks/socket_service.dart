import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_constants.dart';

class SocketService {
  io.Socket? _socket;

  void connect(String token) {
    _socket = io.io(
      '${ApiConstants.apiBASEURL}/notifications',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );
    _socket!.connect();
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
}
