import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/reels/logic/reels_merge.dart';

/// See reels_merge_test.md for what this covers and why.
void main() {
  Post reel(int id, {String likes = '3', String? comments = '1'}) => Post(
        id: id,
        author: null,
        content: 'reel $id',
        createdAt: '2026-08-01T10:00:00Z',
        updatedAt: '2026-08-01T10:00:00Z',
        isLiked: false,
        likesCount: likes,
        commentsCount: comments,
      );

  List<int> idsOf(List<Post> posts) => posts.map((p) => p.id).toList();

  // The reported bug: a reel kept showing a stale like count while its own post
  // screen showed the right one. The screen accepted a delivery only when the
  // list *length* changed, so a corrected count on the same ten reels was
  // silently dropped.
  test('a corrected count on the same reels is accepted', () {
    final current = [reel(1, likes: '12'), reel(2)];
    final incoming = [reel(1, likes: '6'), reel(2)];

    final merge = mergeReels(incoming: incoming, current: current);

    expect(merge.changed, isTrue);
    expect(merge.reels.first.likesCount, '6');
  });

  // Video controllers are cached by index. Rebuilding them for a number that
  // ticked up would interrupt whatever is playing.
  test('a count-only change does not resync the video controllers', () {
    final merge = mergeReels(
      incoming: [reel(1, likes: '6'), reel(2)],
      current: [reel(1, likes: '12'), reel(2)],
    );

    expect(merge.changed, isTrue);
    expect(merge.orderChanged, isFalse);
  });

  test('a delivery that changes nothing is ignored', () {
    final current = [reel(1), reel(2)];

    final merge = mergeReels(incoming: [reel(1), reel(2)], current: current);

    expect(merge.changed, isFalse);
  });

  test('new reels change the order and do resync', () {
    final merge = mergeReels(
      incoming: [reel(1), reel(2), reel(3)],
      current: [reel(1), reel(2)],
    );

    expect(merge.changed, isTrue);
    expect(merge.orderChanged, isTrue);
    expect(idsOf(merge.reels), [1, 2, 3]);
  });

  test('reordered reels of the same length resync', () {
    final merge = mergeReels(
      incoming: [reel(2), reel(1)],
      current: [reel(1), reel(2)],
    );

    expect(merge.orderChanged, isTrue);
  });

  group('the reel the user tapped to get here', () {
    test('stays pinned at index 0', () {
      final merge = mergeReels(
        incoming: [reel(7), reel(8)],
        current: const [],
        initialPost: reel(9),
      );

      expect(idsOf(merge.reels), [9, 7, 8]);
    });

    test('is never also listed further down', () {
      final merge = mergeReels(
        incoming: [reel(7), reel(9), reel(8)],
        current: const [],
        initialPost: reel(9),
      );

      expect(idsOf(merge.reels), [9, 7, 8]);
    });
  });

  group('other engagement numbers', () {
    test('a new comment count counts as a change', () {
      final merge = mergeReels(
        incoming: [reel(1, comments: '4')],
        current: [reel(1, comments: '1')],
      );

      expect(merge.changed, isTrue);
      expect(merge.orderChanged, isFalse);
    });

    test('a like toggled by the viewer counts as a change', () {
      final liked = Post(
        id: 1,
        author: null,
        content: 'reel 1',
        createdAt: '2026-08-01T10:00:00Z',
        updatedAt: '2026-08-01T10:00:00Z',
        isLiked: true,
        likesCount: '3',
        commentsCount: '1',
      );

      final merge = mergeReels(incoming: [liked], current: [reel(1)]);

      expect(merge.changed, isTrue);
    });
  });
}
