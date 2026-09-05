import 'package:riff/core/social/social_platform.dart';
import 'package:riff/core/utils/link_scanner.dart';

class LinkPreview {
  final String url;
  /// One of [SocialPlatform]'s keys, or 'generic'. Produced by the API's
  /// `/meta/link-preview`; the client never invents it.
  final String platform;
  final String type;     // 'track' | 'album' | 'playlist' | 'video' | 'reel' | 'post' | 'generic'
  final String? title;
  final String? description;
  final String? image;
  final String? embedUrl;
  final String? authorName;

  const LinkPreview({
    required this.url,
    required this.platform,
    required this.type,
    this.title,
    this.description,
    this.image,
    this.embedUrl,
    this.authorName,
  });

  factory LinkPreview.fromJson(Map<String, dynamic> json) => LinkPreview(
        url: json['url'] as String? ?? '',
        platform: json['platform'] as String? ?? 'generic',
        type: json['type'] as String? ?? 'generic',
        title: json['title'] as String?,
        description: json['description'] as String?,
        image: json['image'] as String?,
        embedUrl: json['embedUrl'] as String?,
        authorName: json['authorName'] as String?,
      );

  // ─── URL pattern detection ────────────────────────────────────────────────

  /// The first link in [text] that Riff can show a rich preview for, or null.
  ///
  /// This used to be three hand-written regexes, one per platform, each
  /// pinned to a specific content path (`/p/`, `/video/`, `/track/`). They
  /// missed as much as they matched — a `youtu.be` short link, a
  /// `music.youtube.com` URL, an `instagram.com/reel/` with a trailing query,
  /// a share link with an `?si=` tracking parameter — and adding a platform
  /// meant writing a fourth.
  ///
  /// Now the text is scanned for links once, and each is asked which platform
  /// it belongs to. [SocialPlatform.fromUrl] answers from the parsed host, so
  /// every URL shape a platform uses is covered without enumerating them.
  static String? extractFirst(String text) {
    for (final link in scanLinks(text)) {
      if (SocialPlatform.fromUrl(link.url) != null) return link.url;
    }
    return null;
  }

  static bool containsPreviewableUrl(String text) => extractFirst(text) != null;
}
