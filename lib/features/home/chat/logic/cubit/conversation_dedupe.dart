import '../../data/models/chat_models.dart';

/// Collapses duplicate conversations before they reach the chat list.
///
/// There can only ever be one direct conversation between two people, but the
/// API has produced pairs of them: `POST /chat/conversations/direct` checks for
/// an existing one and creates it if absent, with nothing making that atomic, so
/// two taps in flight at once both find nothing and both create. Declining a
/// message request produced the same shape from the other direction — it dropped
/// only the recipient's participant row, leaving a conversation the existence
/// check could no longer match, so the next message started a fresh one.
///
/// Either way the user sees the same person twice: the original thread with all
/// the history, and an empty one. The server side is fixed, but accounts that
/// already have duplicated rows would keep seeing them, so the client collapses
/// them on the way in.
///
/// Keeps the incoming order (the API sorts by most recent activity) and, for
/// each duplicate, keeps whichever copy [isRicherThan] judges to hold the real
/// conversation.
List<Conversation> dedupeConversations(List<Conversation> conversations) {
  final byKey = <String, Conversation>{};
  final order = <String>[];

  for (final conv in conversations) {
    final key = _dedupeKey(conv);
    final existing = byKey[key];
    if (existing == null) {
      byKey[key] = conv;
      order.add(key);
    } else if (isRicherThan(conv, existing)) {
      byKey[key] = conv;
    }
  }

  return [for (final key in order) byKey[key]!];
}

/// Direct conversations collapse per other-participant; everything else (groups,
/// and direct conversations whose other participant is missing) only collapses
/// on its own id.
String _dedupeKey(Conversation conv) {
  final otherId = conv.otherUser?.id;
  if (conv.type == 'direct' && otherId != null && otherId.isNotEmpty) {
    return 'direct:$otherId';
  }
  return 'id:${conv.id}';
}

/// Whether [candidate] is the copy worth keeping over [current].
///
/// Ranked by how much real conversation each one holds, so the thread with the
/// history always wins over the empty duplicate:
///
/// 1. has a latest message
/// 2. more recent activity (`lastMessageAt`)
/// 3. more unread messages
/// 4. older — the original, not the accidental second one
bool isRicherThan(Conversation candidate, Conversation current) {
  if (candidate.id == current.id) return false;

  final candidateHasMessage = candidate.latestMessage != null;
  final currentHasMessage = current.latestMessage != null;
  if (candidateHasMessage != currentHasMessage) return candidateHasMessage;

  final candidateAt = candidate.lastMessageAt;
  final currentAt = current.lastMessageAt;
  if (candidateAt != null || currentAt != null) {
    if (currentAt == null) return true;
    if (candidateAt == null) return false;
    if (!candidateAt.isAtSameMomentAs(currentAt)) {
      return candidateAt.isAfter(currentAt);
    }
  }

  if (candidate.unreadCount != current.unreadCount) {
    return candidate.unreadCount > current.unreadCount;
  }

  return candidate.createdAt.isBefore(current.createdAt);
}
