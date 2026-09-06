import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/social/post_source_link.dart';
import 'package:riff/core/social/social_platform.dart';

/// See post_source_link_test.md for what this covers and why.
void main() {
  const youtubeUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

  group('a post created through the share sheet', () {
    test('uses the stored url and platform', () {
      final source = resolvePostSourceLink(
        sourceUrl: youtubeUrl,
        sourcePlatform: 'youtube',
        content: 'great song',
      );

      expect(source, PostSourceLink(url: youtubeUrl, platform: SocialPlatform.youtube));
    });

    test('derives the platform when only the url was stored', () {
      // Every YouTube link shared before YouTube was recognised is in this
      // state: the URL was kept, the platform was null, so the post had
      // nothing to brand itself with.
      final source = resolvePostSourceLink(
        sourceUrl: youtubeUrl,
        sourcePlatform: null,
        content: null,
      );

      expect(source!.platform, SocialPlatform.youtube);
    });

    test('still offers the link when the host is not one we know', () {
      // An explicit share is a statement of intent, so it earns an
      // affordance whatever the host — the badge just reads "Open link".
      final source = resolvePostSourceLink(
        sourceUrl: 'https://example.com/a',
        sourcePlatform: null,
        content: null,
      );

      expect(source!.url, 'https://example.com/a');
      expect(source.platform, isNull);
    });

    test('prefers the stored url over anything in the body', () {
      final source = resolvePostSourceLink(
        sourceUrl: youtubeUrl,
        sourcePlatform: 'youtube',
        content: 'also see https://www.tiktok.com/@a/video/1',
      );

      expect(source!.url, youtubeUrl);
      expect(source.platform, SocialPlatform.youtube);
    });
  });

  group('a post someone pasted a link into', () {
    test('finds a YouTube link in the body', () {
      // The reported case. These posts wrote no source columns at all, so
      // they had no affordance before and a bare pressable link after.
      final source = resolvePostSourceLink(
        sourceUrl: null,
        sourcePlatform: null,
        content: 'this one is unreal $youtubeUrl',
      );

      expect(source, PostSourceLink(url: youtubeUrl, platform: SocialPlatform.youtube));
    });

    test('finds a short link', () {
      final source = resolvePostSourceLink(
        content: 'listen https://youtu.be/dQw4w9WgXcQ',
      );

      expect(source!.platform, SocialPlatform.youtube);
      expect(source.url, 'https://youtu.be/dQw4w9WgXcQ');
    });

    test('stops the url where the sentence does', () {
      final source = resolvePostSourceLink(
        content: 'watch https://youtu.be/dQw4w9WgXcQ.',
      );

      // A trailing full stop would make the link 404 — the scanner's job,
      // asserted here because this is the path that reaches a real request.
      expect(source!.url, 'https://youtu.be/dQw4w9WgXcQ');
    });

    test('ignores a link from a platform we have no branding for', () {
      // Deliberate asymmetry with the stored-share case above. A URL in a
      // sentence is usually incidental, and a full-width branded chip under
      // every post that mentions a website is worse than the pressable link
      // that is already there.
      final source = resolvePostSourceLink(
        content: 'read https://example.com/a it is good',
      );

      expect(source, isNull);
    });

    test('takes the first recognised link, skipping ones it does not know', () {
      final source = resolvePostSourceLink(
        content: 'https://example.com/a then $youtubeUrl',
      );

      expect(source!.platform, SocialPlatform.youtube);
    });

    test('takes the first when the body has two it knows', () {
      final source = resolvePostSourceLink(
        content: '$youtubeUrl and https://www.tiktok.com/@a/video/1',
      );

      expect(source!.platform, SocialPlatform.youtube);
    });
  });

  group('a post with no link at all', () {
    test('resolves to nothing', () {
      expect(resolvePostSourceLink(), isNull);
      expect(resolvePostSourceLink(content: 'just words'), isNull);
      expect(resolvePostSourceLink(sourceUrl: '', content: ''), isNull);
      expect(resolvePostSourceLink(sourceUrl: '   '), isNull);
    });

    test('a platform recorded without a url is not enough', () {
      // The share receiver used to stamp a platform from a keyword with no
      // link behind it. Nothing should be offered for such a post.
      expect(resolvePostSourceLink(sourcePlatform: 'youtube'), isNull);
    });
  });
}
