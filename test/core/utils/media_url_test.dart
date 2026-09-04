import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/utils/media_url.dart';

/// See media_url_test.md for what this covers and why.
void main() {
  const cloud = 'https://res.cloudinary.com/riffcloud';
  const transform = 'f_mp4,vc_h264,q_auto';

  group('resolve', () {
    test('passes an absolute URL through', () {
      expect(MediaUrl.resolve('$cloud/image/upload/v1/riff/posts/a.jpg'),
          '$cloud/image/upload/v1/riff/posts/a.jpg');
    });

    test('resolves a legacy relative path against the API base', () {
      expect(MediaUrl.resolve('/uploads/a.jpg'),
          '${ApiConstants.apiBASEURL}/uploads/a.jpg');
      expect(MediaUrl.resolve('uploads/a.jpg'),
          '${ApiConstants.apiBASEURL}/uploads/a.jpg');
    });

    test('returns null for nothing', () {
      expect(MediaUrl.resolve(null), isNull);
      expect(MediaUrl.resolve(''), isNull);
    });
  });

  group('videoStream', () {
    test('pins the codec on a Cloudinary video so HEVC never reaches a device', () {
      // The bug this exists for: a tester's Android handset died on
      // `MediaCodecVideoRenderer error … video/hevc`.
      expect(
        MediaUrl.videoStream('$cloud/video/upload/v1/riff/posts/clip.mp4'),
        '$cloud/video/upload/$transform/v1/riff/posts/clip.mp4',
      );
    });

    test('rewrites a .mov shot on an iPhone', () {
      expect(
        MediaUrl.videoStream('$cloud/video/upload/v1712/riff/posts/x.mov'),
        '$cloud/video/upload/$transform/v1712/riff/posts/x.mov',
      );
    });

    test('leaves a voice note alone', () {
      // Cloudinary files audio under the video resource type, but asking it
      // for an H.264 video track of a voice note is asking for a track that
      // does not exist.
      for (final ext in ['m4a', 'mp3', 'aac', 'wav', 'ogg', 'opus']) {
        final url = '$cloud/video/upload/v1/riff/chat/note.$ext';
        expect(MediaUrl.videoStream(url), url, reason: ext);
      }
    });

    test('leaves an image alone', () {
      const url = '$cloud/image/upload/v1/riff/posts/a.jpg';
      expect(MediaUrl.videoStream(url), url);
    });

    test('does not stack a second transformation', () {
      const already = '$cloud/video/upload/$transform/v1/riff/posts/a.mp4';
      expect(MediaUrl.videoStream(already), already);
    });

    test('leaves a non-Cloudinary video alone', () {
      // A self-hosted or third-party URL is not ours to rewrite.
      const url = 'https://example.com/video/upload/v1/clip.mp4';
      expect(MediaUrl.videoStream(url), url);
    });

    test('still resolves a relative path', () {
      expect(MediaUrl.videoStream('/uploads/clip.mp4'),
          '${ApiConstants.apiBASEURL}/uploads/clip.mp4');
    });

    test('returns null for nothing', () {
      expect(MediaUrl.videoStream(null), isNull);
      expect(MediaUrl.videoStream(''), isNull);
    });

    test('handles a URL with no file extension', () {
      expect(
        MediaUrl.videoStream('$cloud/video/upload/v1/riff/posts/noext'),
        '$cloud/video/upload/$transform/v1/riff/posts/noext',
      );
    });
  });
}
