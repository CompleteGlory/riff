import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/features/home/chat/data/repos/chat_repo.dart';
import 'package:riff/features/home/chat/logic/cubit/chats_list_cubit.dart';

import 'chats_list_cubit_test.mocks.dart';

/// See chats_list_cubit_test.md for what this covers and why.
@GenerateMocks([ChatRepo])
void main() {
  late MockChatRepo repo;
  late ChatsListCubit cubit;

  ChatMessage message(String id) => ChatMessage(
        id: id,
        conversationId: 'c',
        type: MessageType.text,
        content: 'hi',
        isDeleted: false,
        createdAt: DateTime(2026, 7, 31, 12),
      );

  Conversation direct(
    String id, {
    required String otherUserId,
    ChatMessage? latestMessage,
    DateTime? createdAt,
  }) =>
      Conversation(
        id: id,
        type: 'direct',
        isRequest: false,
        createdAt: createdAt ?? DateTime(2026, 1, 1),
        participants: const [],
        otherUser: ConversationOtherUser(id: otherUserId, username: otherUserId),
      )..latestMessage = latestMessage;

  List<String> loadedIds(ChatsListState state) =>
      (state as ChatsListLoaded).conversations.map((c) => c.id).toList();

  setUp(() {
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
