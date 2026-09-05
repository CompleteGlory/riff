import 'dart:async';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:riff/core/social/social_platform.dart';

/// Payload produced when Riff is opened via the share sheet.
class SharedContent {
  /// The raw shared text (caption, URL, or both).
  final String text;

  /// First http/https URL extracted from [text], if any.
  final String? url;

  /// The recognised platform's wire key, or null. See [SocialPlatform].
  final String? platform;

  const SharedContent({required this.text, this.url, this.platform});

  bool get isInstagram => platform == SocialPlatform.instagram.key;
  bool get isTikTok    => platform == SocialPlatform.tiktok.key;
  bool get isSpotify   => platform == SocialPlatform.spotify.key;
  bool get isYouTube   => platform == SocialPlatform.youtube.key;

  /// True when the share came from a platform Riff recognises, which is what
  /// makes `CreatePostScreen` record `source_url` / `source_platform` and show
  /// the origin banner.
  ///
  /// Enumerating the platforms here is what made adding one a four-file job
  /// and is why a YouTube share used to arrive as anonymous text; asking
  /// [SocialPlatform] instead means a new platform is recognised the moment it
  /// is declared.
  bool get isSocialShare => SocialPlatform.maybeFromKey(platform) != null;

  /// Text with the source URL stripped out — suitable for pre-filling a caption.
  String get captionText {
    if (url == null) return text.trim();
    return text.replaceAll(url!, '').trim();
  }

  /// Human-readable title extracted from the shared text, e.g. "Song – Artist"
  /// for Spotify shares. Returns null if nothing useful can be extracted.
  String? get displayTitle {
    final caption = captionText;
    if (caption.isEmpty) return null;
    // Spotify shares look like "Song – Artist" or "Listen to Song on Spotify."
    final cleaned = caption
        .replaceAll(RegExp(r'^Listen to\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+on Spotify[.\s]*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}

/// Listens for content shared to Riff from the system share sheet.
///
/// Call [init] once in HomeLayout.initState, [dispose] in dispose.
///
/// • [receivedContent] fires for text/URL shares, including links from any
///   platform in [SocialPlatform].
/// • [receivedMedia]   fires for image/video file shares.
class ShareReceiverService {
  ShareReceiverService._();
  static final ShareReceiverService instance = ShareReceiverService._();

  StreamSubscription<List<SharedMediaFile>>? _sub;

  /// Fires whenever a URL / text is shared to Riff.
  final ValueNotifier<SharedContent?> receivedContent = ValueNotifier(null);

  /// Fires whenever actual media files (images / videos) are shared.
  final ValueNotifier<List<SharedMediaFile>?> receivedMedia = ValueNotifier(null);

  void init() {
    // Cancel any previous subscription so re-init on account switch doesn't
    // create duplicate listeners.
    _sub?.cancel();
    ReceiveSharingIntent.instance.getInitialMedia().then(_handle);
    _sub = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_handle, onError: (_) {});
  }

  void _handle(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    final textItems = files.where(
      (f) => f.type == SharedMediaType.url || f.type == SharedMediaType.text,
    ).toList();

    final media = files.where(
      (f) => f.type != SharedMediaType.url && f.type != SharedMediaType.text,
    ).toList();

    if (textItems.isNotEmpty) {
      // Concatenate all text/url items into one string and extract the URL.
      final raw = textItems.map((f) => f.path).join(' ');
      final url = _extractUrl(raw);
      // The platform comes from the link and only from the link. There used
      // to be a keyword fallback for text with no URL, written for Spotify
      // shares carrying a bare `spotify:` URI — but `_extractUrl` already
      // returns those, so the fallback was only ever reached when there was
      // no link at all, and it then stamped `source_platform` on a post with
      // no `source_url`: "I found this on TikTok" filed as a TikTok share.
      final platform = url == null ? null : _detectPlatform(url);
      receivedContent.value = SharedContent(
        text: raw,
        url: url,
        platform: platform,
      );
    }

    if (media.isNotEmpty) receivedMedia.value = media;

    ReceiveSharingIntent.instance.reset();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static final _urlRegex = RegExp(r'https?://\S+', caseSensitive: false);
  static final _spotifyUriRegex = RegExp(r'spotify:[a-z]+:[A-Za-z0-9]+');

  static String? _extractUrl(String text) {
    // Prefer https/http URL; fall back to spotify: URI.
    final httpMatch = _urlRegex.firstMatch(text)?.group(0)?.replaceAll(RegExp(r'[,.)]+$'), '');
    if (httpMatch != null) return httpMatch;
    return _spotifyUriRegex.firstMatch(text)?.group(0);
  }

  /// Identifies the platform from the shared URL.
  ///
  /// Delegates to [SocialPlatform.fromUrl], which matches on the parsed host
  /// rather than on `url.contains('tiktok.com')` — the substring test this
  /// replaced also said yes to a URL that merely mentioned the domain in a
  /// query parameter.
  static String? _detectPlatform(String url) => SocialPlatform.fromUrl(url)?.key;

  void clearContent() => receivedContent.value = null;
  void clearMedia()   => receivedMedia.value   = null;

  /// Cancels the stream subscription. The ValueNotifiers are intentionally
  /// NOT disposed here because this is a singleton — disposing them would
  /// permanently break them for subsequent HomeLayout instances (e.g. after
  /// an account switch). ValueNotifier disposal is only needed for objects
  /// that are truly discarded; singletons live for the app's lifetime.
  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
