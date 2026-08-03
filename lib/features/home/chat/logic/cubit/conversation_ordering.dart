import '../../data/models/chat_models.dart';

/// Sorts conversations the way the server's `getForUser` does: most recent
/// message first, then most recently created.
///
/// The list normally arrives already ordered and a new message is moved to the
/// front explicitly, so this exists for the one case where neither holds —
/// **deleting** a message. That moves a conversation *backwards*, to wherever
/// the message now on top puts it, and there is no way to express that as
/// "move to position 0". Re-sorting on the timestamps is the only thing that
/// lands it in the right place.
///
/// Pure and total: it copies rather than sorting in place, so callers can't
/// mutate a list another state object is still holding.
List<Conversation> sortConversationsByRecency(List<Conversation> conversations) {
  final sorted = List<Conversation>.from(conversations);
  sorted.sort((a, b) {
    final byRecency = b.sortedAt.compareTo(a.sortedAt);
    if (byRecency != 0) return byRecency;
    return b.createdAt.compareTo(a.createdAt);
  });
  return sorted;
}
