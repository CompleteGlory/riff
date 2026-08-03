import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/features/home/chat/logic/cubit/conversation_ordering.dart';

/// See conversation_ordering_test.md for what this covers and why.
void main() {
  Conversation conv(
    String id, {
    DateTime? lastMessageAt,
    DateTime? createdAt,
  }) =>
      Conversation(
        id: id,
        type: 'direct',
        isRequest: false,
        createdAt: createdAt ?? DateTime(2026, 1, 1),
        participants: const [],
      )..lastMessageAt = lastMessageAt;

  List<String> ids(List<Conversation> list) =>
      list.map((c) => c.id).toList();

  test('puts the most recent message first', () {
    final sorted = sortConversationsByRecency([
      conv('old', lastMessageAt: DateTime(2026, 8, 1)),
      conv('new', lastMessageAt: DateTime(2026, 8, 3)),
      conv('mid', lastMessageAt: DateTime(2026, 8, 2)),
    ]);

    expect(ids(sorted), ['new', 'mid', 'old']);
  });

  // A conversation nobody has spoken in yet — or one whose only message was
  // just deleted — has no last_message_at at all. Sorting it to the bottom
  // would bury a chat someone opened seconds ago underneath months-old
  // history, so it sorts by when it was created instead.
  test('falls back to created_at when there is no message', () {
    final sorted = sortConversationsByRecency([
      conv('spoken', lastMessageAt: DateTime(2026, 8, 1)),
      conv('empty', createdAt: DateTime(2026, 8, 2)),
    ]);

    expect(ids(sorted), ['empty', 'spoken']);
  });

  test('breaks a timestamp tie on the newer conversation', () {
    final at = DateTime(2026, 8, 2);
    final sorted = sortConversationsByRecency([
      conv('older', lastMessageAt: at, createdAt: DateTime(2026, 1, 1)),
      conv('newer', lastMessageAt: at, createdAt: DateTime(2026, 5, 1)),
    ]);

    expect(ids(sorted), ['newer', 'older']);
  });

  // The list handed in belongs to a state object something else may still be
  // holding; sorting it in place would reorder that too.
  test('does not reorder the list it was given', () {
    final input = [
      conv('a', lastMessageAt: DateTime(2026, 8, 1)),
      conv('b', lastMessageAt: DateTime(2026, 8, 3)),
    ];

    sortConversationsByRecency(input);

    expect(ids(input), ['a', 'b']);
  });

  test('handles an empty list', () {
    expect(sortConversationsByRecency([]), isEmpty);
  });
}
