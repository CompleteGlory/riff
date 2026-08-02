import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/home/feed/Ui/widgets/comments/comment_sheet.dart';
import 'package:riff/features/home/feed/data/models/author.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';

/// See comment_author_fallback_test.md for what this covers and why.

void main() {
  final me = Author(
    id: 'me',
    fullName: 'You',
    username: '',
    profileImageUrl: 'https://cdn.example.com/me.jpg',
  );

  final realAuthor = Author(
    id: 'me',
    fullName: 'Magd Kamal',
    username: 'magdkamal',
    profileImageUrl: 'https://cdn.example.com/magd.jpg',
  );

  Comment saved({Author? author}) => Comment(
        id: 12,
        content: 'good',
        author: author,
        createdAt: '2026-08-02T07:09:00Z',
      );

  test('an author-less response keeps the avatar already on screen', () {
    // POST .../comments used to return the freshly inserted row without its
    // `user` relation. Swapping the optimistic comment for it wiped the
    // picture — and the name — off the user's own comment the moment it posted.
    final merged = commentWithAuthorFallback(saved(), me);

    expect(merged.author, same(me));
    expect(merged.author?.profileImageUrl, isNotNull);
  });

  test('it keeps the rest of the server comment', () {
    final merged = commentWithAuthorFallback(saved(), me);

    // Only the author is substituted — the real id matters, because the
    // optimistic one is a negative placeholder the list keys likes off.
    expect(merged.id, 12);
    expect(merged.content, 'good');
    expect(merged.createdAt, '2026-08-02T07:09:00Z');
  });

  test('a real author from the server wins over the placeholder', () {
    final merged = commentWithAuthorFallback(saved(author: realAuthor), me);

    // Now that the API reloads the comment with its author, the response is
    // better than what the client guessed — it carries the real display name
    // instead of "You".
    expect(merged.author, same(realAuthor));
    expect(merged.author?.fullName, 'Magd Kamal');
  });
}
