class LinkPreview {
  final String url;
  final String platform; // 'spotify' | 'tiktok' | 'instagram' | 'generic'
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

  static final _spotifyRe = RegExp(
    r'https?://open\.spotify\.com/(track|album|playlist|artist)/[A-Za-z0-9]+',
  );
  static final _tiktokRe = RegExp(
    r'https?://(www\.tiktok\.com/@[^/]+/video/\d+|vm\.tiktok\.com/[A-Za-z0-9]+)',
  );
  static final _instagramRe = RegExp(
    r'https?://www\.instagram\.com/(p|reel|tv)/[A-Za-z0-9_-]+',
  );

  static String? extractFirst(String text) {
    for (final re in [_spotifyRe, _tiktokRe, _instagramRe]) {
      final m = re.firstMatch(text);
      if (m != null) return m.group(0);
    }
    return null;
  }

  static bool containsPreviewableUrl(String text) => extractFirst(text) != null;
}
