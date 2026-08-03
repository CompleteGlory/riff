import 'package:riff/features/home/feed/data/models/post.dart';

/// What the reels screen should do with a freshly delivered list.
class ReelsMerge {
  const ReelsMerge({
    required this.reels,
    required this.changed,
    required this.orderChanged,
  });

  /// The list to render.
  final List<Post> reels;

  /// Whether anything at all differs from what was on screen. False means the
  /// screen can ignore this delivery entirely.
  final bool changed;

  /// Whether the *sequence of posts* differs, as opposed to only their counts.
  ///
  /// Video controllers are cached by index, so re-syncing them is expensive and
  /// interrupts playback. A like count ticking up must not cost the viewer the
  /// video they're watching.
  final bool orderChanged;
}

/// Decides what the reels screen renders when the cubit delivers [incoming].
///
/// Pure so the rules can be tested without booting a screen full of video
/// controllers — see reels_merge_test.dart.
///
/// Rules:
/// - [initialPost] (the reel the user tapped to get here) stays pinned at index
///   0 and is never duplicated further down.
/// - A delivery whose posts and counts are all identical is ignored, so the
///   screen doesn't churn on a refresh that changed nothing.
/// - Otherwise the incoming list wins. **It is the newer truth, even when it is
///   the same length as what's on screen.**
ReelsMerge mergeReels({
  required List<Post> incoming,
  required List<Post> current,
  Post? initialPost,
}) {
  final merged = initialPost != null
      ? [initialPost, ...incoming.where((r) => r.id != initialPost.id)]
      : incoming;

  final sameOrder = _sameIds(merged, current);
  return ReelsMerge(
    reels: merged,
    changed: !(sameOrder && _sameCounts(merged, current)),
    orderChanged: !sameOrder,
  );
}

bool _sameIds(List<Post> a, List<Post> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id) return false;
  }
  return true;
}

/// Compares the parts of a reel that can change without the list changing:
/// the engagement numbers under it.
bool _sameCounts(List<Post> a, List<Post> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i].likesCount != b[i].likesCount) return false;
    if (a[i].commentsCount != b[i].commentsCount) return false;
    if (a[i].isLiked != b[i].isLiked) return false;
    if (a[i].sharesCount != b[i].sharesCount) return false;
  }
  return true;
}
