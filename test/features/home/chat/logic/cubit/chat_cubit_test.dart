import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/features/home/chat/data/repos/chat_repo.dart';
import 'package:riff/features/home/chat/data/services/chat_socket_service.dart';
import 'package:riff/core/cache/offline_cache.dart';
import 'package:riff/core/helpers/constants.dart';
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
  final _messageCtrl = StreamController<ChatMessage>.broadcast();

  @override
  Stream<Map<String, dynamic>> get onMessageStatus => _statusCtrl.stream;

  @override
  Stream<ChatMessage> get onMessage => _messageCtrl.stream;

  /// Pushes a `message_status` event, as the gateway would.
  void emitStatus(Map<String, dynamic> data) => _statusCtrl.add(data);

  /// Pushes a `message_received` event, as the gateway would.
  void emitMessage(ChatMessage msg) => _messageCtrl.add(msg);

  Future<void> closeFakes() async {
    await _statusCtrl.close();
    await _messageCtrl.close();
  }

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
  Future<bool> sendTextMessage(
    String conversationId,
    String text, {
    String? clientId,
  }) async {
    if (!await ensureConnected()) return false;
    sent.add((conversationId: conversationId, text: text));
    sentClientIds.add(clientId);
    return true;
  }

  final sentClientIds = <String?>[];
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
    SharedPreferences.setMockInitialValues({SharedPrefKeys.userId: 'user-1'});
    // The cache mirrors writes in memory and is a process-wide singleton, so a
    // conversation cached by an earlier test would otherwise be restored here.
    OfflineCache.resetInstanceForTest();
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

  // A message the user typed exists on screen before it exists anywhere else.
  // Showing it only once the server confirms it made every send feel like a
  // stall on a slow connection, and clearing the composer on an emit that went
  // nowhere made a lost message look delivered.
  group('optimistic sending', () {
    List<ChatMessage> messagesOf(ChatState state) =>
        (state as ChatLoaded).messages;

    /// The server's copy of a message the client sent with [clientId].
    ChatMessage confirmed(String id, String text, {String? clientId}) =>
        ChatMessage(
          id: id,
          conversationId: 'conv-1',
          type: MessageType.text,
          content: text,
          isDeleted: false,
          createdAt: DateTime(2026, 8, 1, 10),
          sender: const MessageSender(id: 'user-1'),
          clientId: clientId,
        );

    test('the bubble appears immediately, marked pending', () async {
      await cubit.open(conversation);

      await cubit.sendText('hello');

      final messages = messagesOf(cubit.state);
      expect(messages.length, 1);
      expect(messages.first.content, 'hello');
      expect(messages.first.isPending, isTrue);
      expect(messages.first.clientId, isNotNull);
    });

    test('the correlation id goes out with the message', () async {
      await cubit.open(conversation);
      await cubit.sendText('hello');

      final clientId = messagesOf(cubit.state).first.clientId;
      expect(socket.sentClientIds, [clientId]);
    });

    test('the server echo replaces the optimistic bubble, not duplicates it',
        () async {
      await cubit.open(conversation);
      await cubit.sendText('hello');
      final clientId = messagesOf(cubit.state).first.clientId!;

      socket.emitMessage(confirmed('server-1', 'hello', clientId: clientId));
      await Future<void>.delayed(Duration.zero);

      final messages = messagesOf(cubit.state);
      expect(messages.length, 1, reason: 'one message, not two');
      expect(messages.first.id, 'server-1');
      expect(messages.first.isPending, isFalse);
    });

    // The echo only carries client_id on an API build that knows about it.
    // Against an older one the app still has to reconcile, or every message the
    // user sends shows up twice.
    test('reconciles on content when the server does not echo the id',
        () async {
      await cubit.open(conversation);
      await cubit.sendText('hello');

      socket.emitMessage(confirmed('server-1', 'hello'));
      await Future<void>.delayed(Duration.zero);

      expect(messagesOf(cubit.state).length, 1);
      expect(messagesOf(cubit.state).first.id, 'server-1');
    });

    test('someone else\'s message is never mistaken for our pending one',
        () async {
      await cubit.open(conversation);
      await cubit.sendText('hello');

      socket.emitMessage(ChatMessage(
        id: 'server-9',
        conversationId: 'conv-1',
        type: MessageType.text,
        content: 'hello',
        isDeleted: false,
        createdAt: DateTime(2026, 8, 1, 10),
        sender: const MessageSender(id: 'user-2'),
      ));
      await Future<void>.delayed(Duration.zero);

      final messages = messagesOf(cubit.state);
      expect(messages.length, 2);
      expect(messages.any((m) => m.isPending), isTrue);
    });

    test('a send that never leaves the device is marked failed', () async {
      await cubit.open(conversation);
      socket.connects = false;

      await cubit.sendText('hello');

      final messages = messagesOf(cubit.state);
      expect(messages.single.hasFailed, isTrue);
    });

    test('an unacknowledged send fails once the deadline passes', () async {
      ChatCubit.pendingTimeout = const Duration(milliseconds: 20);
      addTearDown(() => ChatCubit.pendingTimeout = const Duration(seconds: 20));
      await cubit.open(conversation);

      await cubit.sendText('hello');
      expect(messagesOf(cubit.state).single.isPending, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(messagesOf(cubit.state).single.hasFailed, isTrue);
    });

    test('retry re-sends the same text without the user retyping it', () async {
      await cubit.open(conversation);
      socket.connects = false;
      await cubit.sendText('hello');
      final clientId = messagesOf(cubit.state).single.clientId!;

      socket.connects = true;
      await cubit.retryMessage(clientId);

      expect(socket.sent, [(conversationId: 'conv-1', text: 'hello')]);
      expect(messagesOf(cubit.state).single.isPending, isTrue);
    });

    test('discarding a failed message removes it', () async {
      await cubit.open(conversation);
      socket.connects = false;
      await cubit.sendText('hello');
      final clientId = messagesOf(cubit.state).single.clientId!;

      cubit.discardMessage(clientId);

      expect(messagesOf(cubit.state), isEmpty);
    });

    // A read receipt covers what the server has; it cannot possibly cover a
    // message the server has never seen.
    test('a status event does not touch an unsent message', () async {
      await cubit.open(conversation);
      socket.connects = false;
      await cubit.sendText('hello');

      socket.emitStatus({'conversation_id': 'conv-1', 'status': 'read'});
      await Future<void>.delayed(Duration.zero);

      final message = messagesOf(cubit.state).single;
      expect(message.status, MessageStatus.sent);
      expect(message.hasFailed, isTrue);
    });

    test('a media send shows the local file while it uploads', () async {
      await cubit.open(conversation);
      final upload = Completer<ChatMessage>();
      when(repo.uploadMedia(any, any, any, any,
              duration: anyNamed('duration'), clientId: anyNamed('clientId')))
          .thenAnswer((_) => upload.future);

      final sending = cubit.sendMedia('/tmp/pic.jpg', 'pic.jpg', 'image/jpeg');
      await Future<void>.delayed(Duration.zero);

      final pending = messagesOf(cubit.state).single;
      expect(pending.isPending, isTrue);
      expect(pending.type, MessageType.image);
      expect(pending.localMediaPath, '/tmp/pic.jpg');

      upload.complete(ChatMessage(
        id: 'server-2',
        conversationId: 'conv-1',
        type: MessageType.image,
        mediaUrl: 'https://cdn/pic.jpg',
        isDeleted: false,
        createdAt: DateTime(2026, 8, 1, 10),
        sender: const MessageSender(id: 'user-1'),
        clientId: pending.clientId,
      ));
      await sending;

      final settled = messagesOf(cubit.state).single;
      expect(settled.id, 'server-2');
      expect(settled.isPending, isFalse);
    });

    test('a failed upload leaves a retryable bubble', () async {
      await cubit.open(conversation);
      when(repo.uploadMedia(any, any, any, any,
              duration: anyNamed('duration'), clientId: anyNamed('clientId')))
          .thenThrow(Exception('no route to host'));

      await cubit.sendMedia('/tmp/voice.m4a', 'voice.m4a', 'audio/mp4',
          duration: 5);

      final message = messagesOf(cubit.state).single;
      expect(message.hasFailed, isTrue);
      expect(message.type, MessageType.audio);
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
