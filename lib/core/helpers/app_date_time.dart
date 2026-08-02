/// Parsing for timestamps that come off the API.
///
/// Every timestamp column in the API is PostgreSQL `TIMESTAMP` (without time
/// zone) holding UTC, so **the server always means UTC** — but it doesn't always
/// say so on the wire. Depending on the path a payload takes it arrives either
/// as `2026-07-31T10:00:00.000Z` (a JS `Date` run through `JSON.stringify`) or
/// as the naive `2026-07-31T10:00:00` with no designator at all.
///
/// Both shapes used to render three hours early for a UTC+3 user, for two
/// different reasons:
///
/// * **With `Z`** — `DateTime.parse` returns a DateTime with `isUtc == true`.
///   Reading `.hour`/`.minute`/`.day` off it gives *UTC* clock fields, so a
///   message sent at 13:00 local displayed as 10:00. Nothing converted to local
///   before formatting.
/// * **Without `Z`** — `DateTime.parse` returns a *local* DateTime built from
///   digits that were really UTC, so the instant itself is wrong by the offset,
///   and `timeAgo` compounded it by then calling `.toUtc()`.
///
/// [parseServerDateTime] collapses both into one rule: interpret as UTC, return
/// local. Do the conversion once, at the parsing boundary, so every `DateTime`
/// inside the app is already local and callers can format it directly.
library;

/// Parses an API timestamp and returns it in the device's local time zone.
///
/// A string with an explicit offset (`Z` or `+03:00`) is honoured; a naive
/// string is read as UTC, which is what the API means. Returns null when
/// [raw] is null, blank, or unparseable.
DateTime? parseServerDateTime(String? raw) {
  if (raw == null) return null;
  final text = raw.trim();
  if (text.isEmpty) return null;

  // DateTime.parse treats a string with no designator as local. Force UTC so a
  // naive timestamp isn't silently shifted by the device's offset.
  final parsed = DateTime.tryParse(_hasTimeZone(text) ? text : '${text}Z');
  return parsed?.toLocal();
}

/// Like [parseServerDateTime] but falls back to [orElse] (default: now).
DateTime parseServerDateTimeOr(String? raw, {DateTime? orElse}) =>
    parseServerDateTime(raw) ?? orElse ?? DateTime.now();

/// True when [text] already carries a zone designator: a trailing `Z`, or a
/// `±HH:MM` / `±HHMM` offset after the time part.
bool _hasTimeZone(String text) {
  if (text.endsWith('Z') || text.endsWith('z')) return true;
  // Only look after the date, so the '-' separators in 2026-07-31 don't count.
  final timeStart = text.indexOf(RegExp(r'[T ]'));
  if (timeStart == -1) return false;
  return RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(text.substring(timeStart));
}

/// A short human-readable "time since" label for a raw API timestamp string.
///
/// Accepts the same shapes as [parseServerDateTime]. For a `DateTime` a model
/// already parsed, use [timeAgoFrom] — round-tripping it through `toString()`
/// produces a naive string that would be read back as UTC and shifted again.
String timeAgo(String isoDate) {
  final localDateTime = parseServerDateTime(isoDate);
  if (localDateTime == null) return '';
  return timeAgoFrom(localDateTime);
}

/// A short human-readable "time since" label for an already-parsed timestamp.
String timeAgoFrom(DateTime dateTime) {
  final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
  final difference = DateTime.now().difference(localDateTime);

  // Clock skew (or a timestamp stamped a moment ahead of us) shouldn't render
  // as a negative age.
  if (difference.isNegative) return 'just now';

  if (difference.inSeconds < 60) {
    return 'just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return '$weeks week${weeks > 1 ? 's' : ''} ago';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return '$months month${months > 1 ? 's' : ''} ago';
  } else {
    final years = (difference.inDays / 365).floor();
    return '$years year${years > 1 ? 's' : ''} ago';
  }
}
