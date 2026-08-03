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
  final _deletedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _editedCtrl = StreamController<ChatMessage>.broadcast();
  final _reactionCtrl = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get onMessageStatus => _statusCtrl.stream;

  @override
  Stream<ChatMessage> get onMessage => _messageCtrl.stream;

  @override
  Stream<Map<String, dynamic>> get onMessageDeleted => _deletedCtrl.stream;

  @override
  Stream<ChatMessage> get onMessageEdited => _editedCtrl.stream;

  @override
  Stream<Map<String, dynamic>> get onMessageReaction => _reactionCtrl.stream;

  /// Pushes a `message_status` event, as the gateway would.
  void emitStatus(Map<String, dynamic> data) => _statusCtrl.add(data);

  /// Pushes a `message_received` event, as the gateway would.
  void emitMessage(ChatMessage msg) => _messageCtrl.add(msg);

  void emitDeleted(Map<String, dynamic> data) => _deletedCtrl.add(data);
  void emitEdited(ChatMessage msg) => _editedCtrl.add(msg);
  void emitReaction(Map<String, dynamic> data) => _reactionCtrl.add(data);

  Future<void> closeFakes() async {
    await _statusCtrl.close();
    await _messageCtrl.close();
    await _deletedCtrl.close();
    await _editedCtrl.close();
    await _reactionCtrl.close();
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
    String? replyToId,
  }) async {
    if (!await ensureConnected()) return false;
    sent.add((conversationId: conversationId, text: text));
    sentClientIds.add(clientId);
    sentReplyToIds.add(replyToId);
    return true;
  }

  final sentClientIds = <String?>[];
  final sentReplyToIds = <String?>[];
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

  // ── Editing, reactions, remote deletion ────────────────────────────────────

  ChatMessage serverMessage(
    String id, {
    String content = 'hello',
    String senderId = 'user-1',
    DateTime? editedAt,
    List<MessageReaction> reactions = const [],
  }) =>
      ChatMessage(
        id: id,
        conversationId: 'conv-1',
        type: MessageType.text,
        content: content,
        isDeleted: false,
        createdAt: DateTime(2026, 8, 1, 10),
        sender: MessageSender(id: senderId),
        editedAt: editedAt,
        reactions: reactions,
      );

  /// Opens the conversation with [msgs] already in it.
  Future<void> openWith(List<ChatMessage> msgs) async {
    when(repo.getMessages(any, beforeId: anyNamed('beforeId')))
        .thenAnswer((_) async => msgs);
    await cubit.open(conversation);
  }

  ChatMessage messageInState(String id) =>
      (cubit.state as ChatLoaded).messages.firstWhere((m) => m.id == id);

  group('editing', () {
    test('startEditing puts the message in state', () async {
      await openWith([serverMessage('m1')]);

      cubit.startEditing(messageInState('m1'));

      expect((cubit.state as ChatLoaded).editingMessage?.id, 'm1');
    });

    // Replacing an image would be a different image, which is a new message.
    test('refuses to edit anything but text', () async {
      await openWith([
        ChatMessage(
          id: 'm1',
          conversationId: 'conv-1',
          type: MessageType.image,
          isDeleted: false,
          createdAt: DateTime(2026, 8, 1),
        ),
      ]);

      cubit.startEditing(messageInState('m1'));

      expect((cubit.state as ChatLoaded).editingMessage, isNull);
    });

    test('shows the new text before the server confirms it', () async {
      await openWith([serverMessage('m1', content: 'befor')]);
      cubit.startEditing(messageInState('m1'));

      final completer = Completer<ChatMessage>();
      when(repo.editMessage(any, any, any))
          .thenAnswer((_) => completer.future);

      final pending = cubit.submitEdit('before');

      expect(messageInState('m1').content, 'before');
      expect(messageInState('m1').isEdited, isTrue);
      expect((cubit.state as ChatLoaded).editingMessage, isNull,
          reason: 'the composer closes as soon as the edit is submitted');

      completer.complete(
          serverMessage('m1', content: 'before', editedAt: DateTime(2026, 8, 2)));
      await pending;
    });

    // A lost edit has to be visible: silently keeping the new text on screen
    // would leave the user believing the other side can see it.
    test('puts the original text back when the save fails', () async {
      await openWith([serverMessage('m1', content: 'original')]);
      cubit.startEditing(messageInState('m1'));
      when(repo.editMessage(any, any, any)).thenThrow(Exception('offline'));

      expect(await cubit.submitEdit('rewritten'), isFalse);
      expect(messageInState('m1').content, 'original');
      expect(messageInState('m1').isEdited, isFalse,
          reason: 'a failed edit must not leave the "edited" marker behind');
    });

    test('unchanged text just closes the composer', () async {
      await openWith([serverMessage('m1', content: 'same')]);
      cubit.startEditing(messageInState('m1'));

      expect(await cubit.submitEdit('same'), isTrue);
      expect((cubit.state as ChatLoaded).editingMessage, isNull);
      verifyNever(repo.editMessage(any, any, any));
    });

    test('cancelEditing closes the composer', () async {
      await openWith([serverMessage('m1')]);
      cubit.startEditing(messageInState('m1'));

      cubit.cancelEditing();

      expect((cubit.state as ChatLoaded).editingMessage, isNull);
    });

    // The broadcast is serialized for the conversation as a whole, so its
    // status is not this viewer's read state. Taking it wholesale would knock
    // the sender's own message back to a single check.
    test('a broadcast edit changes the text without touching the status',
        () async {
      await openWith([
        serverMessage('m1', content: 'old').copyWith(status: MessageStatus.read),
      ]);

      socket.emitEdited(serverMessage('m1',
          content: 'new', editedAt: DateTime(2026, 8, 2)));
      await Future<void>.delayed(Duration.zero);

      expect(messageInState('m1').content, 'new');
      expect(messageInState('m1').isEdited, isTrue);
      expect(messageInState('m1').status, MessageStatus.read);
    });

    test('ignores an edit for another conversation', () async {
      await openWith([serverMessage('m1', content: 'mine')]);

      socket.emitEdited(ChatMessage(
        id: 'm1',
        conversationId: 'other-conv',
        type: MessageType.text,
        content: 'theirs',
        isDeleted: false,
        createdAt: DateTime(2026, 8, 1),
      ));
      await Future<void>.delayed(Duration.zero);

      expect(messageInState('m1').content, 'mine');
    });
  });

  group('reactions', () {
    final heart = [
      const MessageReaction(emoji: '❤️', userId: 'user-1', username: 'me'),
    ];

    test('shows the reaction before the server confirms it', () async {
      await openWith([serverMessage('m1')]);

      final completer = Completer<List<MessageReaction>>();
      when(repo.reactToMessage(any, any, any))
          .thenAnswer((_) => completer.future);

      final pending = cubit.toggleReaction('m1', '❤️');

      expect(messageInState('m1').reactions.single.emoji, '❤️');
      expect(messageInState('m1').reactions.single.userId, 'user-1');

      completer.complete(heart);
      await pending;
    });

    // One reaction per person: picking a second emoji replaces the first
    // rather than stacking, which is the rule the server applies too.
    test('a different emoji replaces the previous one', () async {
      await openWith([serverMessage('m1', reactions: heart)]);
      when(repo.reactToMessage(any, any, any)).thenAnswer((_) async => [
            const MessageReaction(emoji: '😂', userId: 'user-1'),
          ]);

      await cubit.toggleReaction('m1', '😂');

      expect(messageInState('m1').reactions.map((r) => r.emoji), ['😂']);
    });

    test('the same emoji again takes the reaction back', () async {
      await openWith([serverMessage('m1', reactions: heart)]);
      when(repo.reactToMessage(any, any, any))
          .thenAnswer((_) async => <MessageReaction>[]);

      await cubit.toggleReaction('m1', '❤️');

      expect(messageInState('m1').reactions, isEmpty);
    });

    test('someone else\'s reaction survives mine', () async {
      await openWith([
        serverMessage('m1', reactions: const [
          MessageReaction(emoji: '👍', userId: 'user-2'),
        ]),
      ]);
      when(repo.reactToMessage(any, any, any)).thenAnswer((_) async => const [
            MessageReaction(emoji: '👍', userId: 'user-2'),
            MessageReaction(emoji: '❤️', userId: 'user-1'),
          ]);

      await cubit.toggleReaction('m1', '❤️');

      expect(messageInState('m1').reactions.length, 2);
    });

    test('rolls back when the request fails', () async {
      await openWith([serverMessage('m1', reactions: heart)]);
      when(repo.reactToMessage(any, any, any)).thenThrow(Exception('offline'));

      await cubit.toggleReaction('m1', '😂');

      expect(messageInState('m1').reactions.map((r) => r.emoji), ['❤️']);
    });

    // There is nothing on the server to attach a reaction to yet.
    test('does nothing to a message that is still sending', () async {
      await openWith([]);
      await cubit.sendText('hi');
      final pendingId = (cubit.state as ChatLoaded).messages.first.id;

      await cubit.toggleReaction(pendingId, '❤️');

      expect(messageInState(pendingId).reactions, isEmpty);
      verifyNever(repo.reactToMessage(any, any, any));
    });

    test('a broadcast replaces the whole reaction list', () async {
      await openWith([serverMessage('m1', reactions: heart)]);

      socket.emitReaction({
        'conversation_id': 'conv-1',
        'message_id': 'm1',
        'reactions': [
          {'emoji': '😂', 'user_id': 'user-2', 'username': 'them'},
        ],
      });
      await Future<void>.delayed(Duration.zero);

      expect(messageInState('m1').reactions.single.emoji, '😂');
    });
  });

  group('replying', () {
    test('startReplying points the composer at the message', () async {
      await openWith([serverMessage('m1')]);

      cubit.startReplying(messageInState('m1'));

      expect((cubit.state as ChatLoaded).replyingTo?.id, 'm1');
    });

    // The quote would point at a client-side id nobody else can resolve.
    test('refuses to reply to a message that is still sending', () async {
      await openWith([]);
      await cubit.sendText('hi');
      final pending = (cubit.state as ChatLoaded).messages.first;

      cubit.startReplying(pending);

      expect((cubit.state as ChatLoaded).replyingTo, isNull);
    });

    test('sends the quoted id with the reply', () async {
      await openWith([serverMessage('m1')]);
      cubit.startReplying(messageInState('m1'));

      await cubit.sendText('answering');

      expect(socket.sentReplyToIds.last, 'm1');
    });

    // The reply has to be visibly attached to what it answers straight away —
    // waiting for the server's copy would show it detached for a moment.
    test('the optimistic bubble already carries the quote', () async {
      await openWith([serverMessage('m1', content: 'question?')]);
      cubit.startReplying(messageInState('m1'));

      await cubit.sendText('answering');

      final sent = (cubit.state as ChatLoaded).messages.first;
      expect(sent.replyTo?.id, 'm1');
      expect(sent.replyTo?.content, 'question?');
    });

    test('the banner clears once the reply is sent', () async {
      await openWith([serverMessage('m1')]);
      cubit.startReplying(messageInState('m1'));

      await cubit.sendText('answering');

      expect((cubit.state as ChatLoaded).replyingTo, isNull);
    });

    // The banner is long gone by the time the user taps retry, so the quote
    // has to be held with the outbound payload rather than read from state.
    test('a retry still answers the same message', () async {
      await openWith([serverMessage('m1')]);
      cubit.startReplying(messageInState('m1'));
      socket.connects = false;
      await cubit.sendText('answering');
      final clientId = (cubit.state as ChatLoaded).messages.first.clientId!;
      socket.connects = true;
      socket.sentReplyToIds.clear();

      await cubit.retryMessage(clientId);

      expect(socket.sentReplyToIds.last, 'm1');
    });

    test('cancelReplying clears the banner', () async {
      await openWith([serverMessage('m1')]);
      cubit.startReplying(messageInState('m1'));

      cubit.cancelReplying();

      expect((cubit.state as ChatLoaded).replyingTo, isNull);
    });

    // Rewriting a message and answering one are two different things to be
    // doing with the same text field.
    test('replying and editing are mutually exclusive', () async {
      await openWith([serverMessage('m1'), serverMessage('m2')]);

      cubit.startReplying(messageInState('m1'));
      cubit.startEditing(messageInState('m2'));

      expect((cubit.state as ChatLoaded).replyingTo, isNull);
      expect((cubit.state as ChatLoaded).editingMessage?.id, 'm2');

      cubit.startReplying(messageInState('m1'));

      expect((cubit.state as ChatLoaded).editingMessage, isNull);
      expect((cubit.state as ChatLoaded).replyingTo?.id, 'm1');
    });

    test('a message sent with no reply carries no quote', () async {
      await openWith([]);

      await cubit.sendText('plain');

      expect(socket.sentReplyToIds.last, isNull);
      expect((cubit.state as ChatLoaded).messages.first.replyTo, isNull);
    });
  });

  group('remote deletion', () {
    test('marks the message deleted when the other side deletes it', () async {
      await openWith([serverMessage('m1')]);

      socket.emitDeleted({'conversation_id': 'conv-1', 'message_id': 'm1'});
      await Future<void>.delayed(Duration.zero);

      expect(messageInState('m1').isDeleted, isTrue);
    });

    // Leaving the composer open on a message that no longer exists would let
    // the user save an edit to nothing.
    test('closes the composer if it was editing that message', () async {
      await openWith([serverMessage('m1')]);
      cubit.startEditing(messageInState('m1'));

      socket.emitDeleted({'conversation_id': 'conv-1', 'message_id': 'm1'});
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state as ChatLoaded).editingMessage, isNull);
    });

    // Same for a reply in progress — the quote would point at a message that
    // is no longer there to answer.
    test('drops the reply banner if it quoted that message', () async {
      await openWith([serverMessage('m1')]);
      cubit.startReplying(messageInState('m1'));

      socket.emitDeleted({'conversation_id': 'conv-1', 'message_id': 'm1'});
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state as ChatLoaded).replyingTo, isNull);
    });

    test('ignores a deletion in another conversation', () async {
      await openWith([serverMessage('m1')]);

      socket.emitDeleted({'conversation_id': 'other', 'message_id': 'm1'});
      await Future<void>.delayed(Duration.zero);

      expect(messageInState('m1').isDeleted, isFalse);
    });
  });
}
