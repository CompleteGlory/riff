import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/social/social_platform.dart';

/// See social_platform_test.md for what this covers and why.
void main() {
  group('maybeFromKey', () {
    test('resolves every platform Riff knows', () {
      for (final platform in SocialPlatform.values) {
        expect(SocialPlatform.maybeFromKey(platform.key), platform);
      }
    });

    test('returns null rather than guessing', () {
      // The whole point. The if-chains this replaced ended in `return
      // <spotify value>`, so an unknown platform rendered as Spotify —
      // green chip, "Play on Spotify" — on a YouTube post.
      expect(SocialPlatform.maybeFromKey('threads'), isNull);
      expect(SocialPlatform.maybeFromKey(null), isNull);
      expect(SocialPlatform.maybeFromKey(''), isNull);
    });

    test('is case-insensitive', () {
      expect(SocialPlatform.maybeFromKey('YouTube'), SocialPlatform.youtube);
    });
  });

  group('fromUrl', () {
    void expectPlatform(String url, SocialPlatform? platform) {
      expect(SocialPlatform.fromUrl(url), platform, reason: url);
    }

    test('recognises every YouTube URL shape a share produces', () {
      const youtube = SocialPlatform.youtube;
      expectPlatform('https://www.youtube.com/watch?v=dQw4w9WgXcQ', youtube);
      expectPlatform('https://youtu.be/dQw4w9WgXcQ', youtube);
      expectPlatform('https://www.youtube.com/shorts/dQw4w9WgXcQ', youtube);
      expectPlatform('https://m.youtube.com/watch?v=dQw4w9WgXcQ', youtube);
      expectPlatform('https://music.youtube.com/watch?v=dQw4w9WgXcQ', youtube);
      expectPlatform('https://www.youtube.com/live/dQw4w9WgXcQ', youtube);
      expectPlatform('https://youtube.com/embed/dQw4w9WgXcQ', youtube);
      // Share links carry a tracking parameter; it must not defeat matching.
      expectPlatform('https://youtu.be/dQw4w9WgXcQ?si=AbCdEf', youtube);
    });

    test('still recognises the three platforms that came before', () {
      expectPlatform('https://www.instagram.com/reel/Cxyz/',
          SocialPlatform.instagram);
      expectPlatform('https://instagr.am/p/Cxyz/', SocialPlatform.instagram);
      expectPlatform('https://www.tiktok.com/@someone/video/123',
          SocialPlatform.tiktok);
      expectPlatform('https://vm.tiktok.com/ZMabc/', SocialPlatform.tiktok);
      expectPlatform('https://open.spotify.com/track/abc', SocialPlatform.spotify);
    });

    test('accepts the bare spotify: URI the Spotify app shares', () {
      // It has no host, so host matching alone would miss it.
      expectPlatform('spotify:track:abc123', SocialPlatform.spotify);
    });

    test('matches the host, not a substring of the URL', () {
      // Each of these contains the literal text "youtube.com" and none of
      // them is YouTube. The detector this replaced said yes to all three.
      expectPlatform('https://notyoutube.com/watch?v=x', null);
      expectPlatform('https://youtube.com.phish.example/watch?v=x', null);
      expectPlatform('https://evil.example/?next=https://youtube.com/x', null);
    });

    test('returns null for an unrelated or unparseable url', () {
      expectPlatform('https://example.com/a', null);
      expectPlatform('not a url', null);
      expectPlatform('', null);
    });
  });

  group('branding', () {
    test('every platform has a distinct wire key', () {
      final keys = SocialPlatform.values.map((p) => p.key).toSet();
      expect(keys.length, SocialPlatform.values.length);
    });

    test('the wire keys are exactly what the API accepts', () {
      // These four strings are the contract with the NestJS repo:
      // CreatePostDto's zod enum and MetaService.HOSTS. A rename here that is
      // not mirrored there is rejected at post creation, not at build time.
      expect(SocialPlatform.values.map((p) => p.key).toList(),
          ['instagram', 'tiktok', 'spotify', 'youtube']);
    });

    test('only Spotify is played rather than watched', () {
      expect(SocialPlatform.spotify.isAudio, isTrue);
      expect(SocialPlatform.youtube.isAudio, isFalse);
      expect(SocialPlatform.tiktok.isAudio, isFalse);
      expect(SocialPlatform.instagram.isAudio, isFalse);
    });

    test('TikTok swaps its accent on a light ground, the others do not', () {
      // TikTok's teal is a grey smear on white; everything else survives.
      expect(SocialPlatform.tiktok.accentOn(Brightness.light),
          isNot(SocialPlatform.tiktok.accent));
      expect(SocialPlatform.youtube.accentOn(Brightness.light),
          SocialPlatform.youtube.accent);
    });

    test('Instagram is the only gradient brand', () {
      expect(SocialPlatform.instagram.gradient, isNotNull);
      for (final p in SocialPlatform.values.where((p) => p != SocialPlatform.instagram)) {
        expect(p.gradient, isNull, reason: p.key);
      }
    });
  });
}
