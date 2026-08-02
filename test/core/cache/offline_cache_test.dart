import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/cache/cache_keys.dart';
import 'package:riff/core/cache/offline_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// See offline_cache_test.md for what this covers and why.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late OfflineCache cache;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    root = Directory.systemTemp.createTempSync('riff_offline_cache_test');
    OfflineCache.resetInstanceForTest();
    cache = OfflineCache.instance..rootOverride = root;
  });

  tearDown(() {
    OfflineCache.resetInstanceForTest();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  List<Map<String, dynamic>> posts(int count) => [
        for (var i = 0; i < count; i++) {'id': i, 'content': 'post $i'},
      ];

  group('lists', () {
    test('writes and reads back a list', () async {
      await cache.writeList(CacheKeys.feedPosts, posts(3), limit: 10);

      expect(await cache.readList(CacheKeys.feedPosts), posts(3));
    });

    test('keeps only the first [limit] entries', () async {
      await cache.writeList(CacheKeys.feedPosts, posts(50), limit: 10);
      // Re-read from disk rather than the in-memory mirror, so this proves what
      // was actually stored.
      OfflineCache.resetInstanceForTest();
      final fresh = OfflineCache.instance..rootOverride = root;

      expect((await fresh.readList(CacheKeys.feedPosts))!.length, 10);
    });

    test('a key that was never written reads as null', () async {
      expect(await cache.readList(CacheKeys.reels), isNull);
    });

    test('records when the copy was written', () async {
      await cache.writeList(CacheKeys.feedPosts, posts(1), limit: 10);

      final savedAt = cache.savedAt(CacheKeys.feedPosts);
      expect(savedAt, isNotNull);
      expect(DateTime.now().difference(savedAt!).inSeconds, lessThan(5));
    });
  });

  group('maps', () {
    test('writes and reads back an object', () async {
      await cache.writeMap(CacheKeys.myProfile, {'id': 'u1', 'username': 'mo'});

      expect(await cache.readMap(CacheKeys.myProfile),
          {'id': 'u1', 'username': 'mo'});
    });

    test('reading a list as a map gives null rather than throwing', () async {
      await cache.writeList(CacheKeys.feedPosts, posts(1), limit: 10);

      expect(await cache.readMap(CacheKeys.feedPosts), isNull);
    });
  });

  // A cache is an optimisation. Anything it can't do must degrade to "no
  // cache", never take a screen down with it.
  group('failure handling', () {
    test('a corrupt file reads as no cache', () async {
      await cache.writeList(CacheKeys.feedPosts, posts(1), limit: 10);
      OfflineCache.resetInstanceForTest();
      final fresh = OfflineCache.instance..rootOverride = root;

      final file = File('${root.path}/_anon/${CacheKeys.feedPosts}.json');
      await file.writeAsString('{ this is not json');

      expect(await fresh.readList(CacheKeys.feedPosts), isNull);
    });

    test('a file holding something other than the envelope reads as no cache',
        () async {
      final dir = Directory('${root.path}/_anon')..createSync(recursive: true);
      File('${dir.path}/${CacheKeys.reels}.json')
          .writeAsStringSync(json.encode([1, 2, 3]));

      expect(await cache.readList(CacheKeys.reels), isNull);
    });
  });

  // Sharing a device is normal; showing the previous account's chats is not.
  group('user scoping', () {
    test('each user gets their own partition', () async {
      cache.useScope('user-a');
      await cache.writeList(CacheKeys.feedPosts, posts(2), limit: 10);

      cache.useScope('user-b');
      expect(await cache.readList(CacheKeys.feedPosts), isNull);

      cache.useScope('user-a');
      expect(await cache.readList(CacheKeys.feedPosts), posts(2));
    });

    test('clear wipes every partition', () async {
      cache.useScope('user-a');
      await cache.writeList(CacheKeys.feedPosts, posts(2), limit: 10);
      cache.useScope('user-b');
      await cache.writeList(CacheKeys.reels, posts(2), limit: 10);

      await cache.clear();

      cache.useScope('user-a');
      expect(await cache.readList(CacheKeys.feedPosts), isNull);
      cache.useScope('user-b');
      expect(await cache.readList(CacheKeys.reels), isNull);
    });

    test('remove drops a single bucket', () async {
      await cache.writeList(CacheKeys.feedPosts, posts(2), limit: 10);
      await cache.writeList(CacheKeys.reels, posts(2), limit: 10);

      await cache.remove(CacheKeys.feedPosts);

      expect(await cache.readList(CacheKeys.feedPosts), isNull);
      expect(await cache.readList(CacheKeys.reels), isNotNull);
    });
  });
}
