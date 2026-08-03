import 'dart:async';

/// App-wide notifications about a post that no longer exists.
///
/// A post can be on screen in several places at once — the feed, reels,
/// discover, the author's own profile — and each of those lists is owned by a
/// different cubit, most of them registered as factories, so the widget that
/// deleted the post has no way to reach the others. Instead the delete is
/// announced here and every list that holds posts drops it locally (and prunes
/// it from its offline cache) without waiting for a refetch, which also means
/// the post stays gone while offline.
class PostEvents {
  const PostEvents._();

  static final StreamController<String> _deleted =
      StreamController<String>.broadcast();

  /// Ids of posts that have been deleted, as they are deleted.
  static Stream<String> get deletions => _deleted.stream;

  /// Announce that [postId] was deleted server-side.
  static void notifyDeleted(String postId) {
    if (!_deleted.isClosed) _deleted.add(postId);
  }
}
