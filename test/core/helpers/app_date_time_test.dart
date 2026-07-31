import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/helpers/app_date_time.dart';

/// See app_date_time_test.md for what this covers and why.
void main() {
  // The instant every "same moment" assertion below is anchored to.
  final instant = DateTime.utc(2026, 7, 31, 10, 15, 30);

  /// The same instant, written the three ways the API actually sends it.
  const withZ = '2026-07-31T10:15:30.000Z';
  const naive = '2026-07-31T10:15:30.000';
  const withOffset = '2026-07-31T13:15:30.000+03:00';

  group('parseServerDateTime', () {
    test('reads a timestamp that says UTC', () {
      expect(parseServerDateTime(withZ)!.isAtSameMomentAs(instant), isTrue);
    });

    // The bug: DateTime.parse treats a string with no designator as *local*, so
    // digits that were really UTC got shifted by the device's offset.
    test('reads a timestamp with no designator as UTC, not local', () {
      expect(parseServerDateTime(naive)!.isAtSameMomentAs(instant), isTrue);
    });

    test('honours an explicit offset', () {
      expect(parseServerDateTime(withOffset)!.isAtSameMomentAs(instant), isTrue);
    });

    test('all three spellings resolve to the same instant', () {
      final parsed = [withZ, naive, withOffset].map(parseServerDateTime).toList();

      expect(parsed[0]!.isAtSameMomentAs(parsed[1]!), isTrue);
      expect(parsed[1]!.isAtSameMomentAs(parsed[2]!), isTrue);
    });

    test('accepts a space separator instead of T', () {
      expect(
        parseServerDateTime('2026-07-31 10:15:30')!.isAtSameMomentAs(instant),
        isTrue,
      );
    });

    // The half of the bug that showed up in chat: DateTime.parse('…Z') returns
    // a DateTime with isUtc == true, and the message bubble / chat list / last
    // seen formatters read .hour and .minute straight off it. In UTC+3 a
    // message sent at 13:15 rendered as 10:15 — three hours early. Returning
    // local means those formatters are right without touching them.
    test('returns a local DateTime so clock fields render in local time', () {
      final parsed = parseServerDateTime(withZ)!;
      final expected = instant.toLocal();

      expect(parsed.isUtc, isFalse);
      expect(parsed.hour, expected.hour);
      expect(parsed.minute, expected.minute);
      expect(parsed.day, expected.day);
    });

    test('a naive timestamp renders the same clock fields as a Z one', () {
      final fromNaive = parseServerDateTime(naive)!;
      final fromZ = parseServerDateTime(withZ)!;

      expect(fromNaive.hour, fromZ.hour);
      expect(fromNaive.minute, fromZ.minute);
    });

    group('bad input', () {
      for (final input in <String?>[null, '', '   ', 'not-a-date', 'T::']) {
        test('${input ?? 'null'} → null', () {
          expect(parseServerDateTime(input), isNull);
        });
      }
    });
  });

  group('parseServerDateTimeOr', () {
    test('parses when it can', () {
      expect(
        parseServerDateTimeOr(withZ).isAtSameMomentAs(instant),
        isTrue,
      );
    });

    test('falls back when it cannot', () {
      final fallback = DateTime(2020, 1, 1);

      expect(parseServerDateTimeOr(null, orElse: fallback), fallback);
      expect(parseServerDateTimeOr('junk', orElse: fallback), fallback);
    });

    test('defaults the fallback to now', () {
      final before = DateTime.now();
      final result = parseServerDateTimeOr(null);

      expect(result.isBefore(before.subtract(const Duration(seconds: 1))), isFalse);
    });
  });

  group('timeAgo', () {
    /// [ago] before now, written the way the API writes it.
    String serverStamp(Duration ago, {required bool withZ}) {
      final utc = DateTime.now().toUtc().subtract(ago);
      final iso = utc.toIso8601String(); // always ends in Z
      return withZ ? iso : iso.substring(0, iso.length - 1);
    }

    test('a moment ago reads as just now', () {
      expect(timeAgo(serverStamp(const Duration(seconds: 5), withZ: true)),
          'just now');
    });

    // The other half of the bug. timeAgo used to call .toUtc() on the parse
    // result: harmless for a Z string, but for a naive one it shifted an
    // already-local DateTime *again*, so a message that had just arrived read
    // as "3h ago" for a UTC+3 user.
    test('a naive timestamp reads the same as a Z one', () {
      expect(timeAgo(serverStamp(const Duration(seconds: 5), withZ: false)),
          'just now');
    });

    test('scales through the units', () {
      expect(timeAgo(serverStamp(const Duration(minutes: 5), withZ: true)),
          '5m ago');
      expect(timeAgo(serverStamp(const Duration(hours: 3), withZ: true)),
          '3h ago');
      expect(timeAgo(serverStamp(const Duration(days: 2), withZ: true)),
          '2d ago');
      expect(timeAgo(serverStamp(const Duration(days: 14), withZ: true)),
          '2 weeks ago');
      expect(timeAgo(serverStamp(const Duration(days: 60), withZ: true)),
          '2 months ago');
      expect(timeAgo(serverStamp(const Duration(days: 800), withZ: true)),
          '2 years ago');
    });

    test('both spellings agree at every scale', () {
      for (final ago in const [
        Duration(minutes: 5),
        Duration(hours: 3),
        Duration(days: 2),
        Duration(days: 14),
      ]) {
        expect(
          timeAgo(serverStamp(ago, withZ: false)),
          timeAgo(serverStamp(ago, withZ: true)),
          reason: 'a $ago-old timestamp must read the same either way',
        );
      }
    });

    test('a timestamp slightly in the future is not a negative age', () {
      final future = DateTime.now().toUtc().add(const Duration(seconds: 30));

      expect(timeAgo(future.toIso8601String()), 'just now');
    });

    test('unparseable input renders as empty, not a crash', () {
      expect(timeAgo('not-a-date'), '');
    });
  });

  group('timeAgoFrom', () {
    // Models now hand back local DateTimes. Round-tripping one through
    // toString() produces a naive string that timeAgo would read back as UTC
    // and shift by the offset all over again — hence the DateTime overload.
    test('takes an already-parsed local DateTime', () {
      final fiveMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 5));

      expect(timeAgoFrom(fiveMinutesAgo), '5m ago');
    });

    test('handles a UTC DateTime too', () {
      final fiveMinutesAgo =
          DateTime.now().toUtc().subtract(const Duration(minutes: 5));

      expect(timeAgoFrom(fiveMinutesAgo), '5m ago');
    });

    test('agrees with timeAgo for the same instant', () {
      final utc = DateTime.now().toUtc().subtract(const Duration(hours: 2));

      expect(timeAgoFrom(utc.toLocal()), timeAgo(utc.toIso8601String()));
    });
  });
}
