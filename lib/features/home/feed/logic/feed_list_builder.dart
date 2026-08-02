import 'package:riff/features/commercial/data/models/ad.dart';
import 'package:riff/features/home/feed/data/models/post.dart';

/// Marker for where the trending card goes in the mixed feed list.
///
/// The card needs the trending [Post] to build, but the list is `List<dynamic>`
/// holding posts and ads — a bare [Post] in it would be indistinguishable from
/// an ordinary row. A sentinel keeps the slot explicit.
const Object trendingSlot = Object();

/// Interleaves posts with the trending card and ads.
///
/// Pure so the ordering rules can be tested without booting the feed — see
/// feed_list_builder_test.dart.
///
/// Rules:
/// - The trending card sits after the second post.
/// - One ad every [adEvery] posts.
/// - **A post shown as trending is never also shown as an ordinary row.**
///   The trending post is just a feed post that happens to be trending, so
///   `GET /posts` returns it as well; promoting it to the card without removing
///   it from the list rendered the same post twice, a few rows apart.
List<dynamic> buildFeedItems({
  required List<dynamic> posts,
  Post? trending,
  List<Ad> ads = const [],
  int adEvery = 3,
}) {
  final feedPosts = trending == null
      ? posts
      : posts.where((p) => p is! Post || p.id != trending.id).toList();

  final mixed = <dynamic>[];
  var adIndex = 0;
  var trendingInserted = false;

  for (var i = 0; i < feedPosts.length; i++) {
    mixed.add(feedPosts[i]);

    if (i == 1 && trending != null) {
      mixed.add(trendingSlot);
      trendingInserted = true;
    }

    if (ads.isNotEmpty) {
      final shouldInsert = (i + 1) % adEvery == 0;
      if (shouldInsert && adIndex < ads.length) {
        mixed.add(ads[adIndex % ads.length]);
        adIndex++;
      }
    }
  }

  // Dropping the duplicate can leave fewer than two posts, and the loop only
  // ever inserts at index 1 — without this the trending card would vanish
  // entirely instead of just moving up.
  if (trending != null && !trendingInserted) {
    mixed.add(trendingSlot);
  }

  // Fewer posts than [adEvery] means the loop placed no ad at all.
  if (adIndex == 0 && ads.isNotEmpty) {
    mixed.add(ads[0]);
  }

  return mixed;
}
