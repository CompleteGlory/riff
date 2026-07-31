import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/features/home/chat/logic/cubit/conversation_dedupe.dart';

/// See conversation_dedupe_test.md for what this covers and why.
void main() {
  ChatMessage message(String id, {String conversationId = 'c'}) => ChatMessage(
        id: id,
        conversationId: conversationId,
        type: MessageType.text,
        content: 'hi',
        isDeleted: false,
        createdAt: DateTime(2026, 7, 31, 12),
      );

  Conversation direct(
    String id, {
    required String otherUserId,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    ChatMessage? latestMessage,
    int unreadCount = 0,
  }) =>
      Conversation(
        id: id,
        type: 'direct',
        isRequest: false,
        lastMessageAt: lastMessageAt,
        createdAt: createdAt ?? DateTime(2026, 1, 1),
        participants: const [],
        otherUser: ConversationOtherUser(id: otherUserId, username: otherUserId),
        unreadCount: unreadCount,
      )..latestMessage = latestMessage;

  Conversation groupConv(String id, {DateTime? createdAt}) => Conversation(
        id: id,
        type: 'group',
        name: 'Band',
        isRequest: false,
        createdAt: createdAt ?? DateTime(2026, 1, 1),
        participants: const [],
      );

  List<String> idsOf(List<Conversation> convs) => convs.map((c) => c.id).toList();

  group('leaves clean lists alone', () {
    test('an empty list stays empty', () {
      expect(dedupeConversations([]), isEmpty);
    });

    test('distinct people are all kept, in order', () {
      final list = [
        direct('a', otherUserId: 'u1'),
        direct('b', otherUserId: 'u2'),
        direct('c', otherUserId: 'u3'),
      ];

      expect(idsOf(dedupeConversations(list)), ['a', 'b', 'c']);
    });

    test('groups are never collapsed into each other', () {
      final list = [groupConv('g1'), groupConv('g2')];

      expect(idsOf(dedupeConversations(list)), ['g1', 'g2']);
    });
  });

  // The reported symptom: the same person listed twice, one thread holding the
  // conversation and one empty.
  group('collapses duplicate direct conversations', () {
    test('keeps the one that actually has messages', () {
      final list = [
        direct('empty', otherUserId: 'u1'),
        direct('real', otherUserId: 'u1', latestMessage: message('m1')),
      ];

      expect(idsOf(dedupeConversations(list)), ['real']);
    });

    test('keeps the one with messages even when it comes first', () {
      final list = [
        direct('real', otherUserId: 'u1', latestMessage: message('m1')),
        direct('empty', otherUserId: 'u1'),
      ];

      expect(idsOf(dedupeConversations(list)), ['real']);
    });

    test('keeps the position of the first copy', () {
      final list = [
        direct('a', otherUserId: 'u1'),
        direct('b', otherUserId: 'u2'),
        direct('c', otherUserId: 'u1', latestMessage: message('m1')),
      ];

      // 'c' wins the u1 slot but sits where 'a' was, so the list doesn't jump
      // around under the user mid-scroll.
      expect(idsOf(dedupeConversations(list)), ['c', 'b']);
    });

    test('falls back to the most recent activity', () {
      final list = [
        direct('older', otherUserId: 'u1', lastMessageAt: DateTime(2026, 7, 1)),
        direct('newer', otherUserId: 'u1', lastMessageAt: DateTime(2026, 7, 30)),
      ];

      expect(idsOf(dedupeConversations(list)), ['newer']);
    });

    test('activity beats no activity', () {
      final list = [
        direct('never', otherUserId: 'u1'),
        direct('active', otherUserId: 'u1', lastMessageAt: DateTime(2026, 7, 30)),
      ];

      expect(idsOf(dedupeConversations(list)), ['active']);
    });

    test('then falls back to unread count', () {
      final list = [
        direct('read', otherUserId: 'u1'),
        direct('unread', otherUserId: 'u1', unreadCount: 4),
      ];

      expect(idsOf(dedupeConversations(list)), ['unread']);
    });

    test('finally keeps the original — the older row', () {
      final list = [
        direct('accident', otherUserId: 'u1', createdAt: DateTime(2026, 7, 30)),
        direct('original', otherUserId: 'u1', createdAt: DateTime(2026, 1, 1)),
      ];

      expect(idsOf(dedupeConversations(list)), ['original']);
    });

    test('collapses three copies of the same person down to one', () {
      final list = [
        direct('e1', otherUserId: 'u1'),
        direct('real', otherUserId: 'u1', latestMessage: message('m1')),
        direct('e2', otherUserId: 'u1'),
      ];

      expect(idsOf(dedupeConversations(list)), ['real']);
    });

    test('the same conversation listed twice collapses to one', () {
      final conv = direct('a', otherUserId: 'u1');

      expect(idsOf(dedupeConversations([conv, conv])), ['a']);
    });
  });

  group('does not over-collapse', () {
    // Direct conversations whose other participant is missing are the orphans
    // the old decline handler left behind. They have no user to key on, so
    // they must not all fold into one row.
    test('keeps direct conversations that have no other user separate', () {
      final orphanA = Conversation(
        id: 'a',
        type: 'direct',
        isRequest: false,
        createdAt: DateTime(2026, 1, 1),
        participants: const [],
      );
      final orphanB = Conversation(
        id: 'b',
        type: 'direct',
        isRequest: false,
        createdAt: DateTime(2026, 1, 1),
        participants: const [],
      );

      expect(idsOf(dedupeConversations([orphanA, orphanB])), ['a', 'b']);
    });

    test('a group and a direct chat never collapse together', () {
      final list = [groupConv('g1'), direct('d1', otherUserId: 'u1')];

      expect(idsOf(dedupeConversations(list)), ['g1', 'd1']);
    });
  });

  group('isRicherThan', () {
    test('a conversation is never richer than itself', () {
      final conv = direct('a', otherUserId: 'u1');

      expect(isRicherThan(conv, conv), isFalse);
    });

    test('is decisive either way for the same pair', () {
      final empty = direct('empty', otherUserId: 'u1');
      final real = direct('real', otherUserId: 'u1', latestMessage: message('m1'));

      expect(isRicherThan(real, empty), isTrue);
      expect(isRicherThan(empty, real), isFalse);
    });

    test('identical activity falls through to creation order', () {
      final at = DateTime(2026, 7, 30);
      final older = direct('older',
          otherUserId: 'u1', lastMessageAt: at, createdAt: DateTime(2026, 1, 1));
      final newer = direct('newer',
          otherUserId: 'u1', lastMessageAt: at, createdAt: DateTime(2026, 6, 1));

      expect(isRicherThan(older, newer), isTrue);
      expect(isRicherThan(newer, older), isFalse);
    });
  });
}
