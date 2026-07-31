# `app_date_time_test.dart`

## What it covers

`parseServerDateTime`, `parseServerDateTimeOr`, `timeAgo` and `timeAgoFrom` —
everything that turns an API timestamp into something the UI can render.

- Every spelling the API actually sends (`…Z`, naive, explicit `+03:00`, and a
  space instead of `T`) resolves to the **same instant**.
- The result is a **local** `DateTime`, so `.hour` / `.minute` / `.day` render
  in the device's zone.
- `timeAgo` scales through every unit, agrees between spellings at every scale,
  treats a slightly-future timestamp as "just now" rather than a negative age,
  and returns `''` for garbage instead of throwing.
- `timeAgoFrom` handles both local and UTC `DateTime`s and agrees with
  `timeAgo` for the same instant.

## What's mocked

Nothing — these are pure functions.

## Why the assertions are written relationally

The device time zone isn't controllable from `flutter test`, so nothing asserts
a literal clock value. Instead the tests assert *relationships* that hold in any
zone: naive and `Z` spellings produce the same instant and the same rendered
hour, and a parsed `Z` string matches `DateTime.utc(...).toLocal()`. Those hold
on a UTC CI box and on a UTC+3 laptop alike, and they are exactly the properties
that were broken.

## Regressions locked in

The reported symptom was "everything in the app is three hours earlier". Two
distinct causes, both of which land on a UTC+3 device:

- **Timestamps with `Z`.** `DateTime.parse` returns a `DateTime` with
  `isUtc == true`. The chat bubble, chat list and last-seen formatters read
  `.hour`/`.minute` straight off it and never converted to local, so a message
  sent at 13:15 rendered as 10:15.
- **Timestamps without a designator.** `DateTime.parse` reads those as *local*,
  so digits that were really UTC became the wrong instant — and `timeAgo` then
  called `.toUtc()` on the result, shifting it a second time, so a message that
  had just arrived read as "3h ago".

Every API timestamp column is PostgreSQL `TIMESTAMP` holding UTC, so the rule is
now one line: interpret as UTC, return local, once, at the parsing boundary.
