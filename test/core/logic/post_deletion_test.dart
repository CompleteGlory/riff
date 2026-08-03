import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/logic/post_deletion.dart';
import 'package:riff/features/home/feed/data/models/post.dart';

/// See post_deletion_test.md for what this covers and why.
void main() {
  Post post(int id, {Post? originalPost}) => Post(
        id: id,
        author: null,
        content: 'post $id',
        createdAt: '2026-08-01T10:00:00Z',
        updatedAt: '2026-08-01T10:00:00Z',
        isLiked: false,
        likesCount: '0',
        originalPost: originalPost,
      );

  test('removes the deleted post', () {
    final result = applyPostDeletion([post(1), post(2), post(3)], '2');

    expect(result.map((p) => p.id), [1, 3]);
  });

  test('keeps a share of the deleted post but marks it unavailable', () {
    final share = post(9, originalPost: post(2));

    final result = applyPostDeletion([post(1), share], '2');

    expect(result.map((p) => p.id), [1, 9]);
    final kept = result.firstWhere((p) => p.id == 9);
    expect(kept.originalPost, isNull);
    expect(kept.originalPostDeleted, isTrue);
    expect(kept.content, 'post 9', reason: 'the share itself is untouched');
  });

  test('removes the post and marks its shares in the same pass', () {
    final result =
        applyPostDeletion([post(2), post(9, originalPost: post(2))], '2');

    expect(result.map((p) => p.id), [9]);
    expect(result.single.originalPostDeleted, isTrue);
  });

  test('returns the same list instance when nothing referenced the post', () {
    final posts = [post(1), post(9, originalPost: post(3))];

    // Callers use identity to decide whether to emit or rewrite the cache.
    expect(identical(applyPostDeletion(posts, '2'), posts), isTrue);
  });

  test('does not modify the list it was given', () {
    final posts = [post(1), post(2)];

    applyPostDeletion(posts, '2');

    expect(posts.map((p) => p.id), [1, 2]);
  });
}
