import 'package:riff/features/home/feed/data/models/post.dart';

/// Applies a deletion to a list of posts held by a cubit.
///
/// Two things happen to a list when a post is deleted:
///
/// * the post itself goes;
/// * any *share* of it stays, but loses the post it was quoting — the API keeps
///   the share row and flags it, so the client marks it here too rather than
///   waiting for a refetch that may never come (offline) or may be a while off
///   (a list already on screen).
///
/// Returns a new list; the input is not modified. The result is identical to
/// the input when the deleted post isn't in it, so callers can skip emitting.
List<Post> applyPostDeletion(List<Post> posts, String deletedPostId) {
  var changed = false;
  final result = <Post>[];

  for (final post in posts) {
    if (post.id.toString() == deletedPostId) {
      changed = true;
      continue;
    }
    if (post.originalPost?.id.toString() == deletedPostId) {
      changed = true;
      result.add(post.copyWith(
        clearOriginalPost: true,
        originalPostDeleted: true,
      ));
      continue;
    }
    result.add(post);
  }

  return changed ? result : posts;
}
