import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/home/feed/data/models/author.dart';

/// See author_test.md for what this covers and why.
void main() {
  Author parse(Object? followStatus) => Author.fromJson({
        'id': 'u1',
        'full_name': 'Alice A',
        'username': 'alice',
        'profile_image_url': null,
        if (followStatus != null) 'follow_status': followStatus,
      });

  group('Author.followStatus', () {
    test('reads the field the reels endpoint sends', () {
      expect(parse('following').followStatus, 'following');
      expect(parse('pending').followStatus, 'pending');
      expect(parse('not_following').followStatus, 'not_following');
    });

    test('is null when the payload omits it', () {
      // Only reels returns it so far, and an offline-cached payload written
      // before this shipped will not have it at all.
      expect(parse(null).followStatus, isNull);
    });
  });

  group('isFollowedByViewer', () {
    test('is true for an accepted follow', () {
      // The reported bug: a reel by someone already followed still offered a
      // Follow button, because nothing ever asked this question.
      expect(parse('following').isFollowedByViewer, isTrue);
    });

    test('is true while a request to a private account is pending', () {
      // Offering "Follow" again would send a second request.
      expect(parse('pending').isFollowedByViewer, isTrue);
    });

    test('is false when not following', () {
      expect(parse('not_following').isFollowedByViewer, isFalse);
    });

    test('is false when the status is missing', () {
      // A cached reel from before this field existed must still show a usable
      // button rather than hiding it on a guess.
      expect(parse(null).isFollowedByViewer, isFalse);
    });

    test('is false for a status it does not recognise', () {
      expect(parse('blocked').isFollowedByViewer, isFalse);
    });
  });

  group('hasPendingFollowRequest', () {
    test('separates a sent request from an accepted follow', () {
      // The two share a hidden Follow button but not a label: one says
      // "Requested", the other shows nothing.
      expect(parse('pending').hasPendingFollowRequest, isTrue);
      expect(parse('following').hasPendingFollowRequest, isFalse);
      expect(parse('not_following').hasPendingFollowRequest, isFalse);
      expect(parse(null).hasPendingFollowRequest, isFalse);
    });
  });

  test('survives a round trip through JSON', () {
    // Reels are written to the offline cache, so the status has to come back
    // out of a re-decoded payload intact.
    final restored = Author.fromJson(parse('following').toJson());

    expect(restored.followStatus, 'following');
    expect(restored.isFollowedByViewer, isTrue);
  });
}
