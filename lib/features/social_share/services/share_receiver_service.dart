import 'dart:async';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Payload produced when Riff is opened via the share sheet.
class SharedContent {
  /// The raw shared text (caption, URL, or both).
  final String text;

  /// First http/https URL extracted from [text], if any.
  final String? url;

  /// 'instagram' | 'tiktok' | 'spotify' — set when URL is from those platforms.
  final String? platform;

  const SharedContent({required this.text, this.url, this.platform});

  bool get isInstagram  => platform == 'instagram';
  bool get isTikTok     => platform == 'tiktok';
  bool get isSpotify    => platform == 'spotify';
  /// True for all platforms that open CreatePostScreen (IG, TikTok, Spotify).
  bool get isSocialShare => isInstagram || isTikTok || isSpotify;

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
/// • [receivedContent] fires for text/URL shares (including IG/TikTok links).
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
      // Detect platform from URL first; fall back to keyword detection so
      // Spotify shares without an https URL (e.g. spotify: URI only) still
      // get identified correctly.
      final platform = url != null
          ? _detectPlatform(url)
          : _detectPlatformFromText(raw);
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

  static String? _detectPlatform(String url) {
    if (url.contains('instagram.com') || url.contains('instagr.am')) return 'instagram';
    if (url.contains('tiktok.com')) return 'tiktok';
    if (url.contains('spotify.com') || url.startsWith('spotify:')) return 'spotify';
    return null;
  }

  /// Fallback when no extractable URL was found — infer platform from keywords.
  static String? _detectPlatformFromText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('spotify')) return 'spotify';
    if (lower.contains('tiktok')) return 'tiktok';
    if (lower.contains('instagram')) return 'instagram';
    return null;
  }

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
