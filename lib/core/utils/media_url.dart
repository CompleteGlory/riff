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
}
