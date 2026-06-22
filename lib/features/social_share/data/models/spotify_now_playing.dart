/// The currently playing Spotify track for the authenticated user.
class SpotifyNowPlaying {
  final String trackName;
  final String artistName;
  final String? albumName;
  final String? albumArtUrl;
  final String? trackUrl;
  final bool isPlaying;
  final int? durationMs;
  final int? progressMs;

  const SpotifyNowPlaying({
    required this.trackName,
    required this.artistName,
    this.albumName,
    this.albumArtUrl,
    this.trackUrl,
    required this.isPlaying,
    this.durationMs,
    this.progressMs,
  });

  factory SpotifyNowPlaying.fromJson(Map<String, dynamic> json) {
    final item    = json['item']    as Map<String, dynamic>?;
    final album   = item?['album'] as Map<String, dynamic>?;
    final artists = (item?['artists'] as List<dynamic>?)
        ?.map((a) => a['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    final images = (album?['images'] as List<dynamic>?);
    // Pick the 300px image (index 1) or fallback to first
    final artUrl = images != null && images.isNotEmpty
        ? (images.length > 1 ? images[1]['url'] : images[0]['url']) as String?
        : null;

    return SpotifyNowPlaying(
      trackName:  item?['name']  as String? ?? 'Unknown Track',
      artistName: artists?.join(', ') ?? 'Unknown Artist',
      albumName:  album?['name'] as String?,
      albumArtUrl: artUrl,
      trackUrl:   (item?['external_urls'] as Map?)?['spotify'] as String?,
      isPlaying:  json['is_playing'] as bool? ?? false,
      durationMs: json['item']?['duration_ms'] as int?,
      progressMs: json['progress_ms'] as int?,
    );
  }
}
