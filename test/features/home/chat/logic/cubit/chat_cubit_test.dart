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

  tearDown(() async => cubit.close());

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
