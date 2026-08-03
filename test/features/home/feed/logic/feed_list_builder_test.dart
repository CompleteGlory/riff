import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/commercial/data/models/ad.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/logic/feed_list_builder.dart';

/// See feed_list_builder_test.md for what this covers and why.

void main() {
  Post post(int id) => Post(
        id: id,
        author: null,
        content: null,
        createdAt: '',
        updatedAt: '',
        isLiked: false,
        likesCount: '0',
      );

  List<int> postIdsIn(List<dynamic> items) =>
      items.whereType<Post>().map((p) => p.id).toList();

  int trendingSlotCount(List<dynamic> items) =>
      items.where((i) => identical(i, trendingSlot)).length;

  group('the trending post is never shown twice', () {
    test('it is dropped from the ordinary rows', () {
      final posts = [post(1), post(2), post(3), post(4)];

      final items = buildFeedItems(posts: posts, trending: post(3));

      // The trending post is a normal feed post that also happens to be
      // trending, so GET /posts returns it too. Promoting it to the card
      // without removing it rendered the same post twice, rows apart.
      expect(postIdsIn(items), [1, 2, 4]);
      expect(trendingSlotCount(items), 1);
    });

    test('the card still appears when the duplicate was the only other post',
        () {
      final posts = [post(1), post(7)];

      final items = buildFeedItems(posts: posts, trending: post(7));

      // Filtering leaves one post, and the card is normally inserted after the
      // second — it must not vanish just because the list got shorter.
      expect(postIdsIn(items), [1]);
      expect(trendingSlotCount(items), 1);
    });

    test('the card appears even when the feed is only the trending post', () {
      final items = buildFeedItems(posts: [post(9)], trending: post(9));

      expect(postIdsIn(items), isEmpty);
      expect(trendingSlotCount(items), 1);
    });

    test('a later page containing it is filtered too', () {
      // Pagination appends; the filter runs over the whole accumulated list.
      final posts = [post(1), post(2), post(3), post(4), post(5), post(6)];

      final items = buildFeedItems(posts: posts, trending: post(6));

      expect(postIdsIn(items), [1, 2, 3, 4, 5]);
      expect(trendingSlotCount(items), 1);
    });
  });

  group('ordering', () {
    test('the card sits after the second post', () {
      final items =
          buildFeedItems(posts: [post(1), post(2), post(3)], trending: post(9));

      expect(items.indexWhere((i) => identical(i, trendingSlot)), 2);
    });

    test('no trending post means no slot', () {
      final items = buildFeedItems(posts: [post(1), post(2), post(3)]);

      expect(trendingSlotCount(items), 0);
      expect(postIdsIn(items), [1, 2, 3]);
    });

    test('nothing at all yields an empty list', () {
      expect(buildFeedItems(posts: []), isEmpty);
    });
  });

  group('ads', () {
    Ad ad(int id) =>
        Ad(id: id, viewCount: 0, storeManagerId: 'sm', createdAt: '');
    final ads = [ad(1), ad(2)];

    test('one ad every adEvery posts', () {
      final items = buildFeedItems(
        posts: [post(1), post(2), post(3), post(4), post(5), post(6)],
        ads: ads,
        adEvery: 3,
      );

      expect(items.whereType<Ad>().length, 2);
    });

    test('a short feed still gets one ad', () {
      final items = buildFeedItems(posts: [post(1)], ads: ads, adEvery: 3);

      expect(items.whereType<Ad>().length, 1);
    });

    test('dropping the trending duplicate does not drop the ad', () {
      // Two posts in, one removed as the trending duplicate — the loop then
      // never reaches the adEvery boundary, so the fallback has to cover it.
      final items = buildFeedItems(
        posts: [post(1), post(2)],
        trending: post(2),
        ads: ads,
        adEvery: 3,
      );

      expect(items.whereType<Ad>().length, 1);
    });
  });
}
