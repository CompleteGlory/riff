import 'package:flutter/material.dart';

/// The external platforms a Riff post can be shared from, and how each one
/// looks wherever it is shown.
///
/// This exists because the same platform switch was written **four** times —
/// in the feed chip, the full-screen reel card, the small reel badge and the
/// create-post banner — and every copy had the same shape:
///
/// ```dart
/// if (_isInstagram) return <instagram value>;
/// if (_isTikTok)    return <tiktok value>;
/// return <spotify value>;          // <- no neutral default
/// ```
///
/// Spotify was the fallthrough, so a platform nobody had written a branch for
/// did not degrade to something neutral: it silently rendered as Spotify.
/// Green chip, "Play on Spotify", Spotify's icon — on a YouTube post. Four
/// copies meant four chances to add a platform to three of them and ship the
/// fourth still lying. Adding one here now reaches every surface at once, and
/// [maybeFromKey] returns null rather than guessing, so an unrecognised value
/// renders as a neutral link instead of as whichever platform happened to sit
/// last in an if-chain.
///
/// [key] is the wire value: it must match `posts.source_platform` in the API
/// and the `platform` field of `GET /api/meta/link-preview`. The two repos
/// agree on these four strings and nothing else.
enum SocialPlatform {
  instagram(
    key: 'instagram',
    displayName: 'Instagram',
    accent: Color(0xFFDD2A7B),
    icon: Icons.camera_alt_outlined,
    reelBackground: Color(0xFF120818),
  ),
  tiktok(
    key: 'tiktok',
    displayName: 'TikTok',
    accent: Color(0xFF69C9D0),
    icon: Icons.play_circle_outline_rounded,
    reelBackground: Color(0xFF080808),
    // TikTok's teal reads as a mid-grey smear on white; the wordmark's black
    // is the only part of its palette that survives a light background.
    lightAccent: Color(0xFF010101),
    buttonColor: Color(0xFFFF0050),
  ),
  spotify(
    key: 'spotify',
    displayName: 'Spotify',
    accent: Color(0xFF1DB954),
    icon: Icons.music_note_rounded,
    reelBackground: Color(0xFF0A1A0A),
    // Spotify green is bright enough that white text on it fails contrast;
    // Spotify's own buttons use black for exactly this reason.
    onAccent: Colors.black,
    isAudio: true,
  ),
  youtube(
    key: 'youtube',
    displayName: 'YouTube',
    accent: Color(0xFFFF0000),
    icon: Icons.smart_display_rounded,
    reelBackground: Color(0xFF1A0808),
  );

  const SocialPlatform({
    required this.key,
    required this.displayName,
    required this.accent,
    required this.icon,
    required this.reelBackground,
    this.lightAccent,
    this.onAccent = Colors.white,
    this.buttonColor,
    this.isAudio = false,
  });

  /// The value stored in `posts.source_platform`. Never localise this.
  final String key;

  /// The platform's own name. A proper noun — deliberately not localised, and
  /// not translated in the Arabic strings either.
  final String displayName;

  /// Brand colour, used for borders, icons and accents on dark grounds.
  final Color accent;

  /// Shown instead of [accent] on a light ground, when the brand colour is
  /// illegible there. Null means [accent] works on both.
  final Color? lightAccent;

  /// Text/icon colour that is readable **on top of** [accent].
  final Color onAccent;

  /// Fill for a solid call-to-action, when the brand uses a different colour
  /// for buttons than for accents. Defaults to [accent].
  final Color? buttonColor;

  /// A glyph, not a network logo. Every one of these used to be fetched from
  /// `https://logo.clearbit.com/<domain>` at runtime — a host that no longer
  /// resolves at all, so all four badges have been quietly falling through to
  /// their error widgets. An icon that ships in the binary cannot 404, cannot
  /// leak which posts a user is looking at to a third party, and renders
  /// instantly offline.
  final IconData icon;

  /// Ground colour behind a full-screen link-only reel.
  final Color reelBackground;

  /// You listen to it rather than watch it, so the call to action reads
  /// "Play on …" instead of "Watch on …".
  final bool isAudio;

  /// Brand colour that works against the current theme.
  Color accentOn(Brightness brightness) =>
      brightness == Brightness.light ? (lightAccent ?? accent) : accent;

  /// Fill for a solid button.
  Color get solidButtonColor => buttonColor ?? accent;

  /// A faint wash of the brand colour, for a chip's fill.
  Color get tint => accent.withValues(alpha: 0.07);

  /// Instagram is the one brand whose mark is a gradient rather than a colour.
  /// Callers that can render a gradient use this; the rest use [accent], which
  /// is a colour sampled from it.
  static const instagramGradient = LinearGradient(
    colors: [
      Color(0xFF405DE6),
      Color(0xFF833AB4),
      Color(0xFFC13584),
      Color(0xFFE1306C),
      Color(0xFFFD1D1D),
      Color(0xFFF77737),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Gradient? get gradient => this == instagram ? instagramGradient : null;

  /// Resolves a stored `source_platform` value.
  ///
  /// Returns null for null, for the empty string, and for any value this
  /// build does not know — an older client reading a post created by a newer
  /// one, say. Callers render a neutral link in that case, which is honest;
  /// the alternative an if-chain gave was to render it as Spotify.
  static SocialPlatform? maybeFromKey(String? key) {
    if (key == null || key.isEmpty) return null;
    final lower = key.toLowerCase();
    for (final platform in values) {
      if (platform.key == lower) return platform;
    }
    return null;
  }

  /// Hosts belonging to each platform, matched as whole labels.
  static const _hosts = <SocialPlatform, List<String>>{
    instagram: ['instagram.com', 'instagr.am'],
    tiktok: ['tiktok.com'],
    spotify: ['spotify.com', 'spotify.link'],
    youtube: ['youtube.com', 'youtu.be', 'youtube-nocookie.com'],
  };

  /// Identifies the platform a URL belongs to, or null.
  ///
  /// Matching is on the parsed **host**, as whole dot-separated labels — not
  /// `url.contains('youtube.com')`, which the previous detector used and which
  /// says yes to `https://notyoutube.com.example/`, to
  /// `https://evil.example/?next=youtube.com`, and to a bare mention of the
  /// domain in a caption. Subdomains match (`m.`, `music.`, `vm.`, `open.`),
  /// so every real share URL is covered without trusting a substring.
  static SocialPlatform? fromUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    // Spotify's app shares a `spotify:track:…` URI, which has no host.
    if (trimmed.toLowerCase().startsWith('spotify:')) return spotify;

    final uri = Uri.tryParse(trimmed);
    final host = uri?.host.toLowerCase();
    if (host == null || host.isEmpty) return null;

    for (final entry in _hosts.entries) {
      for (final domain in entry.value) {
        if (host == domain || host.endsWith('.$domain')) return entry.key;
      }
    }
    return null;
  }
}
