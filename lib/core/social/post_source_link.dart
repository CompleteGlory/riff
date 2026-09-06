import 'package:riff/core/social/social_platform.dart';
import 'package:riff/core/utils/link_scanner.dart';

/// The external thing a post points at, and what it is.
class PostSourceLink {
  const PostSourceLink({required this.url, required this.platform});

  final String url;

  /// Null only for a stored share from a host this build does not recognise.
  /// A link found in the body is never promoted unless its platform is known.
  final SocialPlatform? platform;

  @override
  bool operator ==(Object other) =>
      other is PostSourceLink && other.url == url && other.platform == platform;

  @override
  int get hashCode => Object.hash(url, platform);

  @override
  String toString() => 'PostSourceLink($url, ${platform?.key})';
}

/// Works out what a post links to, from whatever evidence it has.
///
/// `source_url` / `source_platform` are only written when a post is created
/// through the system share sheet. Anyone who pasted a YouTube link into the
/// composer — which is how most of them arrive — produced a post with those
/// columns null and the URL sitting in the body, so it rendered as prose with
/// no affordance at all, and as a bare pressable link once links became
/// pressable. Reading the body closes that gap for every post already in the
/// database, without a migration and without rewriting anyone's content.
///
/// Three sources, in order of how much they can be trusted:
///
/// 1. **A stored `source_url`.** An explicit share. It wins even if the body
///    contains other links, and it earns an affordance whatever the host is —
///    the user deliberately shared *that*.
/// 2. **`source_platform`, then the URL's own host.** Falling back to the host
///    is what fixes shares recorded before their platform was recognised: a
///    YouTube link shared into an older build stored the URL and a null
///    platform, so it had nothing to brand itself with.
/// 3. **The first recognised link in the body.** Only promoted when
///    [SocialPlatform.fromUrl] knows the host. That asymmetry is deliberate:
///    an explicit share is a statement of intent, whereas a URL in a sentence
///    is often incidental, and putting a full-width branded chip under every
///    post that happens to mention a website would be worse than leaving it as
///    the pressable link it already is.
PostSourceLink? resolvePostSourceLink({
  String? sourceUrl,
  String? sourcePlatform,
  String? content,
}) {
  final stored = (sourceUrl ?? '').trim();
  if (stored.isNotEmpty) {
    return PostSourceLink(
      url: stored,
      platform: SocialPlatform.maybeFromKey(sourcePlatform) ??
          SocialPlatform.fromUrl(stored),
    );
  }

  for (final link in scanLinks(content ?? '')) {
    final platform = SocialPlatform.fromUrl(link.url);
    if (platform != null) {
      return PostSourceLink(url: link.url, platform: platform);
    }
  }

  return null;
}
