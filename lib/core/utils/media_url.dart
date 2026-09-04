import 'package:riff/core/networks/api_constants.dart';

/// Single source of truth for resolving media URLs returned by the API.
///
/// The API currently stores absolute URLs (Cloudinary: https://res.cloudinary.com/…).
/// Legacy records may contain relative paths (/uploads/…) which are resolved
/// against [ApiConstants.apiBASEURL] as a fallback.
///
/// To migrate to a different storage provider in the future, only this file
/// needs to change — no widgets or models need to be touched.
class MediaUrl {
  MediaUrl._();

  /// Resolves [raw] to a usable URL string.
  /// Returns null if [raw] is null or empty.
  static String? resolve(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return '${ApiConstants.apiBASEURL}$raw';
    return '${ApiConstants.apiBASEURL}/$raw';
  }

  /// Convenience for non-nullable callers.
  static String resolveOrEmpty(String raw) => resolve(raw) ?? '';

  /// Cloudinary delivery transformation that forces a universally decodable
  /// video stream: H.264 in an MP4 container, quality chosen by Cloudinary.
  static const _h264Delivery = 'f_mp4,vc_h264,q_auto';

  /// Extensions that live under Cloudinary's `video/` resource type but are
  /// really audio — voice notes. Re-encoding one as H.264 video would ask
  /// Cloudinary to build a video track that does not exist.
  static const _audioExtensions = {'m4a', 'mp3', 'aac', 'wav', 'ogg', 'opus', 'weba'};

  /// Resolves [raw] for playback in a video player.
  ///
  /// Phones record HEVC (H.265), and Cloudinary stored whatever arrived. Some
  /// Android devices cannot decode it: a tester's handset died on
  /// `MediaCodecVideoRenderer error … video/hevc` even though the container
  /// reported `format_supported=YES`. Uploads are transcoded to H.264 now, but
  /// clips posted before that are still HEVC in storage, so the codec is also
  /// pinned here, on the way out. Cloudinary builds the H.264 rendition once
  /// and caches it, so this fixes existing posts without re-uploading anything.
  ///
  /// Anything that is not a Cloudinary video URL — a local file, an external
  /// link, an image, a voice note, or a URL that already carries a
  /// transformation — is returned exactly as [resolve] would give it.
  static String? videoStream(String? raw) {
    final resolved = resolve(raw);
    if (resolved == null) return null;

    const marker = '/video/upload/';
    final markerAt = resolved.indexOf(marker);
    if (markerAt == -1) return resolved;
    if (!resolved.contains('res.cloudinary.com')) return resolved;

    final tail = resolved.substring(markerAt + marker.length);
    if (tail.isEmpty) return resolved;

    // Already transformed by someone else — don't stack a second set.
    if (tail.startsWith(_h264Delivery)) return resolved;

    // A voice note is not video, whatever resource type it is filed under.
    final lastDot = resolved.lastIndexOf('.');
    if (lastDot > resolved.lastIndexOf('/')) {
      final extension = resolved.substring(lastDot + 1).toLowerCase();
      if (_audioExtensions.contains(extension)) return resolved;
    }

    return resolved.replaceFirst(marker, '$marker$_h264Delivery/');
  }
}