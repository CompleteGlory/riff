// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Handles outbound deep links and sharing to TikTok, Instagram, and Spotify.
///
/// Strategy:
///   • Try to open the native app first via a custom URL scheme.
///   • Fall back to the web URL (opens in browser) if the app is not installed.
///   • For content-sharing (sharing a post/video to TikTok or Instagram), use
///     [share_plus] with the system share sheet, which lets the OS route to the
///     target app.
class PlatformShareService {
  PlatformShareService._();

  // ─── Generic URL opener ───────────────────────────────────────────────────

  /// Opens [url] in the native app if possible, else falls back to browser.
  static Future<void> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Spotify ──────────────────────────────────────────────────────────────

  /// Opens a Spotify track/album/playlist in the Spotify app.
  /// e.g. https://open.spotify.com/track/ABC → spotify:track:ABC
  static Future<void> openSpotify(String webUrl) async {
    final spotifyUri = _webToSpotifyScheme(webUrl);
    if (spotifyUri != null) {
      final uri = Uri.parse(spotifyUri);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    // Fall back to web URL
    await openUrl(webUrl);
  }

  /// Shares the Spotify URL (song/playlist) via the system share sheet.
  static Future<void> shareSpotifyLink(String url, {String? title}) async {
    await Share.share(
      title != null ? '$title\n$url' : url,
      subject: title ?? 'Listen on Spotify',
    );
  }

  // ─── TikTok ───────────────────────────────────────────────────────────────

  /// Opens a TikTok video URL in the TikTok app.
  static Future<void> openTikTok(String webUrl) async {
    // TikTok supports https:// deep links directly if app is installed.
    final uri = Uri.tryParse(webUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    await openUrl(webUrl);
  }

  /// Shares a video file or URL to TikTok via the system share sheet.
  /// [filePath] — local path to a video file (mp4 / mov)
  /// [caption]  — optional caption text
  static Future<void> shareVideoToTikTok(
    BuildContext context, {
    required String filePath,
    String? caption,
  }) async {
    final file = XFile(filePath);
    final text = caption ?? '';
    await Share.shareXFiles([file], text: text, subject: 'Share to TikTok');
  }

  /// Shares a web URL via the TikTok share sheet (text-only share).
  static Future<void> shareLinkToTikTok(String url, {String? caption}) async {
    final text = [if (caption != null) caption, url].join('\n');
    await Share.share(text, subject: 'Share to TikTok');
  }

  // ─── Instagram ────────────────────────────────────────────────────────────

  /// Opens a specific Instagram post / reel URL in the Instagram app.
  static Future<void> openInstagram(String webUrl) async {
    // Instagram handles https:// links as deep links when app is installed.
    final uri = Uri.tryParse(webUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    await openUrl(webUrl);
  }

  /// Shares an image to Instagram Stories via the custom URL scheme.
  /// Requires [imageBytes] as PNG data.
  static Future<void> shareImageToInstagramStories({
    required String imageFilePath,
  }) async {
    // Instagram Stories deep link — iOS only, Android falls back to share sheet
    final igUri = Uri.parse(
      'instagram-stories://share?source_application=com.riff.app',
    );
    if (await canLaunchUrl(igUri)) {
      await launchUrl(igUri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: system share sheet with image
      final file = XFile(imageFilePath);
      await Share.shareXFiles([file], subject: 'Share to Instagram');
    }
  }

  /// Shares a video file to Instagram Reels via the system share sheet.
  static Future<void> shareVideoToInstagram({
    required String videoFilePath,
    String? caption,
  }) async {
    final file = XFile(videoFilePath);
    await Share.shareXFiles(
      [file],
      text: caption ?? '',
      subject: 'Share to Instagram',
    );
  }

  /// Shares any URL via the system share sheet (platform-agnostic).
  static Future<void> shareUrl(String url, {String? message}) async {
    final text = [if (message != null) message, url].join('\n');
    await Share.share(text);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Converts an open.spotify.com URL to a spotify: URI scheme.
  /// https://open.spotify.com/track/ABC?si=... → spotify:track:ABC
  static String? _webToSpotifyScheme(String webUrl) {
    final uri = Uri.tryParse(webUrl);
    if (uri == null) return null;
    // Path is like /track/ABC or /album/ABC or /playlist/ABC
    final segments = uri.pathSegments; // ['track', 'ABC']
    if (segments.length < 2) return null;
    final type = segments[0]; // track | album | playlist | artist
    final id   = segments[1]; // alphanumeric Spotify ID
    return 'spotify:$type:$id';
  }
}
