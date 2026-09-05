import 'package:flutter/widgets.dart';

import 'package:riff/core/social/social_platform.dart';
import 'package:riff/generated/l10n.dart';

/// The user-facing wording for a [SocialPlatform].
///
/// Separate from the enum so the model stays free of `BuildContext` and the
/// generated `S` class, and can be unit-tested as plain data.
///
/// These labels used to be hardcoded English in four widgets — 'Play on
/// Instagram', 'Watch on TikTok', 'Sharing from Spotify' — in an app whose
/// every other string is localised. One phrase per shape, with the platform
/// name substituted in, means Arabic gets the whole family for four entries
/// rather than one per platform per surface.
extension SocialPlatformLabels on SocialPlatform {
  /// The call to action: "Play on Spotify", "Watch on YouTube".
  ///
  /// [displayName] is never translated — a brand name is a proper noun, and
  /// the Arabic strings deliberately leave it in Latin script, which is how
  /// these platforms write themselves in Arabic UIs.
  String openLabel(BuildContext context) => isAudio
      ? S.of(context).playOnPlatform(displayName)
      : S.of(context).watchOnPlatform(displayName);

  /// The create-post banner: "Sharing from TikTok".
  String sharingFromLabel(BuildContext context) =>
      S.of(context).sharingFromPlatform(displayName);
}

/// What to call a link whose platform this build does not recognise.
String neutralLinkLabel(BuildContext context) => S.of(context).openExternalLink;
