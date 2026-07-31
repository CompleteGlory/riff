import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';

/// See chat_models_test.md for what this covers and why.
void main() {
  // Every timestamp the API sends is UTC — the columns are PostgreSQL
  // TIMESTAMP holding UTC — but depending on the path a payload takes it says
  // so with a trailing Z or not at all. Both must land on the same instant, in
  // local time, or the chat screens render three hours early in UTC+3.
  final instant = DateTime.utc(2026, 7, 31, 10, 15, 30);
  const withZ = '2026-07-31T10:15:30.000Z';
  const naive = '2026-07-31T10:15:30.000';

  group('ChatMessage.fromJson', () {
    Map<String, dynamic> json(String createdAt) => {
          'id': 'm1',
          'conversation_id': 'c1',
          'type': 'text',
          'content': 'hi',
          'created_at': createdAt,
        };

    test('parses a Z timestamp to the right instant, in local time', () {
      final msg = ChatMessage.fromJson(json(withZ));

      expect(msg.createdAt.isAtSameMomentAs(instant), isTrue);
      expect(msg.createdAt.isUtc, isFalse,
          reason: 'the bubble formatter reads .hour/.minute straight off this');
      expect(msg.createdAt.hour, instant.toLocal().hour);
    });

    test('parses a naive timestamp to the same instant', () {
      expect(
        ChatMessage.fromJson(json(naive))
            .createdAt
            .isAtSameMomentAs(instant),
        isTrue,
      );
    });

    test('both spellings render the same clock time', () {
      expect(
        ChatMessage.fromJson(json(naive)).createdAt.hour,
        ChatMessage.fromJson(json(withZ)).createdAt.hour,
      );
    });

    test('a missing timestamp falls back rather than throwing', () {
      final msg = ChatMessage.fromJson({
        'id': 'm1',
        'conversation_id': 'c1',
        'type': 'text',
      });

      expect(msg.createdAt, isNotNull);
    });
  });

  group('Conversation.fromJson', () {
    Map<String, dynamic> json({String? lastMessageAt, String? lastSeen}) => {
          'id': 'c1',
          'type': 'direct',
          'created_at': withZ,
          if (lastMessageAt != null) 'last_message_at': lastMessageAt,
          'participants': <dynamic>[],
          'other_user': {
            'id': 'u1',
            'username': 'someone',
            if (lastSeen != null) 'last_seen': lastSeen,
          },
        };

    test('created_at lands on the right instant in local time', () {
      final conv = Conversation.fromJson(json());

      expect(conv.createdAt.isAtSameMomentAs(instant), isTrue);
      expect(conv.createdAt.isUtc, isFalse);
    });

    test('last_message_at accepts both spellings', () {
      expect(
        Conversation.fromJson(json(lastMessageAt: withZ))
            .lastMessageAt!
            .isAtSameMomentAs(instant),
        isTrue,
      );
      expect(
        Conversation.fromJson(json(lastMessageAt: naive))
            .lastMessageAt!
            .isAtSameMomentAs(instant),
        isTrue,
      );
    });

    test('a null last_message_at stays null', () {
      expect(Conversation.fromJson(json()).lastMessageAt, isNull);
    });

    // The chat header prints last-seen as a bare HH:mm.
    test('other_user.last_seen is local so the header reads correctly', () {
      final conv = Conversation.fromJson(json(lastSeen: withZ));
      final lastSeen = conv.otherUser!.lastSeen!;

      expect(lastSeen.isAtSameMomentAs(instant), isTrue);
      expect(lastSeen.isUtc, isFalse);
      expect(lastSeen.hour, instant.toLocal().hour);
    });

    test('a missing last_seen stays null', () {
      expect(Conversation.fromJson(json()).otherUser!.lastSeen, isNull);
    });
  });
}
