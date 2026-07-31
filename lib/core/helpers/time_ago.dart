/// `timeAgo` now lives alongside the rest of the API-timestamp handling in
/// `app_date_time.dart` — it has to parse server timestamps the same way
/// everything else does, or relative and absolute times end up disagreeing by
/// the device's UTC offset.
///
/// Kept as a re-export so existing `import '.../time_ago.dart';` call sites
/// keep working.
library;

export 'app_date_time.dart' show timeAgo;
