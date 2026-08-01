import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/features/home/chat/data/repos/chat_repo.dart';
import 'package:riff/features/home/chat/data/services/chat_socket_service.dart';
import 'package:riff/features/home/chat/logic/cubit/chat_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_cubit_test.mocks.dart';

/// See chat_cubit_test.md for what this covers and why.

/// Records what the cubit asks of the socket without opening one.
class _FakeChatSocketService extends ChatSocketService {
  /// Whether the (re)connection attempt succeeds.
  bool connects = true;

  // Own controllers so tests can push socket events in. The real ones are
  // private to ChatSocketService, so a subclass can't reach them.
  final _statusCtrl = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get onMessageStatus => _statusCtrl.stream;

  /// Pushes a `message_status` event, as the gateway would.
  void emitStatus(Map<String, dynamic> data) => _statusCtrl.add(data);

  Future<void> closeFakes() => _statusCtrl.close();

  int ensureConnectedCalls = 0;
  final joined = <String>[];
  final sent = <({String conversationId, String text})>[];

  @override
  Future<bool> ensureConnected() async {
    ensureConnectedCalls++;
    return connects;
  }

  @override
  void joinConversation(String conversationId) => joined.add(conversationId);

  @override
  void leaveConversation(String conversationId) {}

  @override
  void markAsRead(String conversationId) {}

  @override
  Future<bool> sendTextMessage(String conversationId, String text) async {
    if (!await ensureConnected()) return false;
    sent.add((conversationId: conversationId, text: text));
    return true;
  }
}

@GenerateMocks([ChatRepo])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockChatRepo repo;
  late _FakeChatSocketService socket;
  late ChatCubit cubit;

  final conversation = Conversation(
    id: 'conv-1',
    type: 'direct',
    isRequest: false,
    createdAt: DateTime(2026, 1, 1),
    participants: const [],
    otherUser: const ConversationOtherUser(id: 'user-2'),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = MockChatRepo();
    socket = _FakeChatSocketService();
    cubit = ChatCubit(repo, socket);
    when(repo.getMessages(any, beforeId: anyNamed('beforeId')))
        .thenAnswer((_) async => <ChatMessage>[]);
  });

  tearDown(() async {
    await cubit.close();
    await socket.closeFakes();
  });

  group('open', () {
    test('loads the conversation and joins its room', () async {
      await cubit.open(conversation);

      expect(cubit.state, isA<ChatLoaded>());
      expect(socket.joined, ['conv-1']);
    });

    // Opening a chat straight from a push notification means the app has been
    // idle long enough for the 15-minute access token to expire. The gateway
    // verifies that token during the handshake and hangs up when it fails, so
    // the socket has to be re-established (with a refreshed token) before the
    // room join — otherwise the screen loads over HTTP but can neither send nor
    // receive, which is the "I have to restart the app to reply" bug.
    test('re-establishes the socket before joining', () async {
      await cubit.open(conversation);

      expect(socket.ensureConnectedCalls, greaterThanOrEqualTo(1));
    });

    test('still records the room when the socket is down', () async {
      socket.connects = false;

      await cubit.open(conversation);

      expect(cubit.state, isA<ChatLoaded>(),
          reason: 'history still loads over HTTP');
      // The join is recorded even though the emit goes nowhere: the socket
      // service replays the current conversation on its next successful
      // connect, so the user lands back in the room automatically.
      expect(socket.joined, ['conv-1']);
    });

    test('surfaces a load failure', () async {
      when(repo.getMessages(any, beforeId: anyNamed('beforeId')))
          .thenThrow(Exception('boom'));

      await cubit.open(conversation);

      expect(cubit.state, isA<ChatError>());
    });
  });

  group('sendText', () {
    test('sends over the socket and reports success', () async {
      await cubit.open(conversation);

      expect(await cubit.sendText('hello'), isTrue);
      expect(socket.sent, [(conversationId: 'conv-1', text: 'hello')]);
    });

    // sendText() used to be fire-and-forget: it emitted into a dead socket and
    // the composer cleared, so the user believed the message had gone.
    test('reports failure when the socket cannot be reached', () async {
      await cubit.open(conversation);
      socket.connects = false;

      expect(await cubit.sendText('hello'), isFalse);
      expect(socket.sent, isEmpty);
    });

    test('reports failure when no conversation is open', () async {
      expect(await cubit.sendText('hello'), isFalse);
      expect(socket.sent, isEmpty);
    });
  });

  // "I read his voice notes but he still sees one check."
  //
  // Read receipts only ever existed as a live socket event, and the REST
  // serializer had no status field at all — so MessageStatusX.fromString(null)
  // fell through to `sent` and every message reset to a single check as soon as
  // the sender reopened the chat. The API now derives status from
  // conversation_participants.last_read_at and sends it with every message.
  group('read receipts', () {
    ChatMessage message(String id, {MessageStatus status = MessageStatus.sent}) =>
        ChatMessage(
          id: id,
          conversationId: 'conv-1',
          type: MessageType.audio,
          duration: 8,
          isDeleted: false,
          createdAt: DateTime(2026, 8, 1, 10),
          status: status,
        );

    /// Status keyed by message id. open() reverses the repo's order (newest
    /// first, for the reverse ListView), so index-based assertions read
    /// backwards — key by id instead.
    Map<String, MessageStatus> statusById(ChatState state) => {
          for (final m in (state as ChatLoaded).messages) m.id: m.status,
        };

    test('opening the chat picks up the status the server reports', () async {
      // The sender reopens the conversation. Whatever happened while they were
      // away must come back from the API, not be reset to one check.
      when(repo.getMessages(any, beforeId: anyNamed('beforeId'))).thenAnswer(
        (_) async => [
          message('m1', status: MessageStatus.read),
          message('m2', status: MessageStatus.read),
        ],
      );

      await cubit.open(conversation);

      expect(statusById(cubit.state),
          {'m1': MessageStatus.read, 'm2': MessageStatus.read});
    });

    test('a read event upgrades every message in the conversation', () async {
      when(repo.getMessages(any, beforeId: anyNamed('beforeId')))
          .thenAnswer((_) async => [message('m1'), message('m2')]);
      await cubit.open(conversation);

      socket.emitStatus({'conversation_id': 'conv-1', 'status': 'read'});
      await Future<void>.delayed(Duration.zero);

      expect(statusById(cubit.state),
          {'m1': MessageStatus.read, 'm2': MessageStatus.read});
    });

    test('a message_id scopes the upgrade to that message', () async {
      when(repo.getMessages(any, beforeId: anyNamed('beforeId')))
          .thenAnswer((_) async => [message('m1'), message('m2')]);
      await cubit.open(conversation);

      socket.emitStatus({
        'conversation_id': 'conv-1',
        'status': 'delivered',
        'message_id': 'm1',
      });
      await Future<void>.delayed(Duration.zero);

      expect(statusById(cubit.state),
          {'m1': MessageStatus.delivered, 'm2': MessageStatus.sent});
    });

    test('never downgrades an already-read message', () async {
      when(repo.getMessages(any, beforeId: anyNamed('beforeId'))).thenAnswer(
        (_) async => [message('m1', status: MessageStatus.read)],
      );
      await cubit.open(conversation);

      socket.emitStatus({'conversation_id': 'conv-1', 'status': 'delivered'});
      await Future<void>.delayed(Duration.zero);

      expect(statusById(cubit.state), {'m1': MessageStatus.read});
    });

    test('ignores an event for a different conversation', () async {
      when(repo.getMessages(any, beforeId: anyNamed('beforeId')))
          .thenAnswer((_) async => [message('m1')]);
      await cubit.open(conversation);

      socket.emitStatus({'conversation_id': 'other', 'status': 'read'});
      await Future<void>.delayed(Duration.zero);

      expect(statusById(cubit.state), {'m1': MessageStatus.sent});
    });
  });

  group('ensureConnected', () {
    test('reconnects and re-joins the open conversation', () async {
      await cubit.open(conversation);
      socket.joined.clear();

      expect(await cubit.ensureConnected(), isTrue);
      expect(socket.joined, ['conv-1'],
          reason: 'a reconnected socket starts in no rooms');
    });

    test('reports failure when the reconnect does not come up', () async {
      await cubit.open(conversation);
      socket.joined.clear();
      socket.connects = false;

      expect(await cubit.ensureConnected(), isFalse);
      expect(socket.joined, isEmpty,
          reason: 'nothing to re-join into on a dead socket');
    });
  });
}
