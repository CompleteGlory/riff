import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/features/home/chat/data/repos/chat_repo.dart';
import 'package:riff/core/cache/offline_cache.dart';
import 'package:riff/features/home/chat/logic/cubit/chats_list_cubit.dart';

import 'chats_list_cubit_test.mocks.dart';

/// See chats_list_cubit_test.md for what this covers and why.
@GenerateMocks([ChatRepo])
void main() {
  late MockChatRepo repo;
  late ChatsListCubit cubit;

  ChatMessage message(String id, {String content = 'hi'}) => ChatMessage(
        id: id,
        conversationId: 'a',
        type: MessageType.text,
        content: content,
        isDeleted: false,
        createdAt: DateTime(2026, 7, 31, 12),
        // Only set when the message has actually been rewritten — the edit
        // tests below assert on this rather than on the text alone.
        editedAt: content == 'hi' ? null : DateTime(2026, 8, 1),
      );

  Conversation direct(
    String id, {
    required String otherUserId,
    ChatMessage? latestMessage,
    DateTime? createdAt,
    DateTime? lastMessageAt,
  }) =>
      Conversation(
        id: id,
        type: 'direct',
        isRequest: false,
        createdAt: createdAt ?? DateTime(2026, 1, 1),
        participants: const [],
        otherUser: ConversationOtherUser(id: otherUserId, username: otherUserId),
      )
        ..latestMessage = latestMessage
        ..lastMessageAt = lastMessageAt;

  List<String> loadedIds(ChatsListState state) =>
      (state as ChatsListLoaded).conversations.map((c) => c.id).toList();

  setUp(() {
    // The cache mirrors writes in memory, and it is a process-wide singleton —
    // without this, a list cached by an earlier test is still there to be
    // restored by a later one that expects an empty start.
    OfflineCache.resetInstanceForTest();
    repo = MockChatRepo();
    cubit = ChatsListCubit(repo);
    when(repo.getMessageRequests()).thenAnswer((_) async => <Conversation>[]);
  });

  tearDown(() async => cubit.disposePermanently());

  Future<void> loadWith(List<Conversation> convs) async {
    when(repo.getConversations()).thenAnswer((_) async => convs);
    await cubit.load();
  }

  // The reported symptom: a person shows up twice in the chat list, once with
  // the messages and once as an empty thread. The server now prevents new ones,
  // but accounts that already have duplicated rows keep receiving them, so the
  // list collapses them on arrival.
  group('load', () {
    test('collapses a duplicated person into the thread with the messages',
        () async {
      await loadWith([
        direct('empty', otherUserId: 'u1'),
        direct('real', otherUserId: 'u1', latestMessage: message('m1')),
        direct('other', otherUserId: 'u2'),
      ]);

      expect(loadedIds(cubit.state), ['real', 'other']);
    });

    test('leaves a list with no duplicates untouched', () async {
      await loadWith([
        direct('a', otherUserId: 'u1'),
        direct('b', otherUserId: 'u2'),
      ]);

      expect(loadedIds(cubit.state), ['a', 'b']);
    });

    test('collapses duplicated message requests too', () async {
      when(repo.getConversations()).thenAnswer((_) async => <Conversation>[]);
      when(repo.getMessageRequests()).thenAnswer((_) async => [
            direct('r-empty', otherUserId: 'u9'),
            direct('r-real', otherUserId: 'u9', latestMessage: message('m1')),
          ]);

      await cubit.load();

      final requests = (cubit.state as ChatsListLoaded).requests;
      expect(requests.map((c) => c.id), ['r-real']);
    });

    test('surfaces a load failure', () async {
      when(repo.getConversations()).thenThrow(Exception('offline'));

      await cubit.load();

      expect(cubit.state, isA<ChatsListError>());
    });
  });

  group('onMessageDeleted', () {
    // Deleting the newest message in a conversation moves that conversation
    // *down* the list — unlike a new message, which always moves it to the
    // top. There is no way to express that as a reorder, so the list is
    // re-sorted on the timestamps the server sends with the deletion.
    test('re-sorts the list on the message that is now newest', () async {
      await loadWith([
        direct('recent', otherUserId: 'u1', lastMessageAt: DateTime(2026, 8, 3)),
        direct('older', otherUserId: 'u2', lastMessageAt: DateTime(2026, 8, 2)),
      ]);

      // 'recent' loses its only recent message; what's left predates 'older'.
      cubit.onMessageDeleted(
        'recent',
        latestMessage: message('m-old'),
        lastMessageAt: DateTime(2026, 8, 1),
      );

      expect(loadedIds(cubit.state), ['older', 'recent']);
    });

    test('leaves the order alone when an older message is deleted', () async {
      await loadWith([
        direct('recent', otherUserId: 'u1', lastMessageAt: DateTime(2026, 8, 3)),
        direct('older', otherUserId: 'u2', lastMessageAt: DateTime(2026, 8, 2)),
      ]);

      // The newest message survives, so the sort key doesn't move.
      cubit.onMessageDeleted(
        'recent',
        latestMessage: message('m-newest'),
        lastMessageAt: DateTime(2026, 8, 3),
      );

      expect(loadedIds(cubit.state), ['recent', 'older']);
    });

    test('updates the row preview to the remaining message', () async {
      await loadWith([
        direct('a',
            otherUserId: 'u1',
            latestMessage: message('m2'),
            lastMessageAt: DateTime(2026, 8, 3)),
      ]);

      cubit.onMessageDeleted(
        'a',
        latestMessage: message('m1'),
        lastMessageAt: DateTime(2026, 8, 1),
      );

      final conv = (cubit.state as ChatsListLoaded).conversations.single;
      expect(conv.latestMessage?.id, 'm1');
      expect(conv.lastMessageAt, DateTime(2026, 8, 1));
    });

    // The last message in a conversation leaves it with nothing to preview and
    // no sort key — it falls back to when it was created rather than vanishing
    // off the bottom of the list.
    test('clears the preview when nothing is left', () async {
      await loadWith([
        direct('a',
            otherUserId: 'u1',
            latestMessage: message('m1'),
            lastMessageAt: DateTime(2026, 8, 3),
            createdAt: DateTime(2026, 7, 1)),
      ]);

      cubit.onMessageDeleted('a', latestMessage: null, lastMessageAt: null);

      final conv = (cubit.state as ChatsListLoaded).conversations.single;
      expect(conv.latestMessage, isNull);
      expect(conv.sortedAt, DateTime(2026, 7, 1));
    });

    test('ignores a conversation that is not in the list', () async {
      await loadWith([direct('a', otherUserId: 'u1')]);

      cubit.onMessageDeleted('somewhere-else',
          latestMessage: null, lastMessageAt: null);

      expect(loadedIds(cubit.state), ['a']);
    });
  });

  group('onMessageEdited', () {
    test('refreshes the preview when the edited message is the newest',
        () async {
      await loadWith([
        direct('a', otherUserId: 'u1', latestMessage: message('m1')),
      ]);

      cubit.onMessageEdited(message('m1', content: 'rewritten'));

      final conv = (cubit.state as ChatsListLoaded).conversations.single;
      expect(conv.latestMessage?.content, 'rewritten');
      expect(conv.latestMessage?.isEdited, isTrue);
    });

    // Editing something further up the history changes nothing the row shows.
    test('leaves the preview alone for an older message', () async {
      await loadWith([
        direct('a', otherUserId: 'u1', latestMessage: message('m2')),
      ]);

      cubit.onMessageEdited(message('m1', content: 'rewritten'));

      final conv = (cubit.state as ChatsListLoaded).conversations.single;
      expect(conv.latestMessage?.content, 'hi');
    });
  });

  group('prependConversation', () {
    test('adds someone new to the top', () async {
      await loadWith([direct('a', otherUserId: 'u1')]);

      cubit.prependConversation(direct('b', otherUserId: 'u2'));

      expect(loadedIds(cubit.state), ['b', 'a']);
    });

    test('ignores a conversation already in the list', () async {
      await loadWith([direct('a', otherUserId: 'u1')]);

      cubit.prependConversation(direct('a', otherUserId: 'u1'));

      expect(loadedIds(cubit.state), ['a']);
    });

    // Starting a chat from search returns the existing conversation under a
    // *different* object; without the dedupe that put the same person in the
    // list twice.
    test('does not add a second row for someone already listed', () async {
      await loadWith([
        direct('existing', otherUserId: 'u1', latestMessage: message('m1')),
      ]);

      cubit.prependConversation(direct('fresh', otherUserId: 'u1'));

      expect(loadedIds(cubit.state), ['existing']);
    });
  });

  group('acceptRequest', () {
    test('moves the conversation out of requests and into the list', () async {
      when(repo.getConversations()).thenAnswer((_) async => <Conversation>[]);
      when(repo.getMessageRequests())
          .thenAnswer((_) async => [direct('r1', otherUserId: 'u1')]);
      await cubit.load();

      cubit.acceptRequest(direct('r1', otherUserId: 'u1'));

      final state = cubit.state as ChatsListLoaded;
      expect(state.conversations.map((c) => c.id), ['r1']);
      expect(state.requests, isEmpty);
    });

    // A refresh landing between the accept call and this state update already
    // moved the conversation across; without the dedupe it went in twice.
    test('does not duplicate a conversation a refresh already moved', () async {
      await loadWith([
        direct('r1', otherUserId: 'u1', latestMessage: message('m1')),
      ]);

      cubit.acceptRequest(direct('r1', otherUserId: 'u1'));

      expect(loadedIds(cubit.state), ['r1']);
    });
  });
}
