import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';

/// A tiny JSON-file store for the last-known-good copy of the screens the user
/// looks at most, so a dead connection shows real content instead of a spinner
/// or an error page.
///
/// Design notes:
///
/// * **Files, not SharedPreferences.** These are lists of decoded API objects;
///   round-tripping them through a preferences string would work but grows the
///   preferences blob that every `SharedPrefHelper` call reads.
/// * **Scoped per user.** Everything lives under `offline_cache/<userId>/`, so
///   signing in as someone else can never surface the previous account's feed
///   or chats. [clear] wipes the whole directory on sign-out.
/// * **Never throws.** A cache is an optimisation; a failed read or write must
///   degrade to "no cache", never break the screen that asked for it.
/// * **Memory-mirrored.** Reads are served from memory after the first hit, so
///   a cubit can consult the cache on every load without touching the disk.
class OfflineCache {
  OfflineCache._();

  static OfflineCache instance = OfflineCache._();

  /// Replaces the singleton. Tests only.
  @visibleForTesting
  static void setInstanceForTest(OfflineCache cache) => instance = cache;

  /// Restores the real singleton. Tests only.
  @visibleForTesting
  static void resetInstanceForTest() => instance = OfflineCache._();

  /// Overrides the directory the cache lives in. Tests only — production
  /// resolves it from `path_provider`.
  @visibleForTesting
  Directory? rootOverride;

  Directory? _root;
  String? _scope;
  final Map<String, _CacheEntry> _memory = {};

  // ── Scope ─────────────────────────────────────────────────────────────────

  /// The user id the cache is currently partitioned by. Resolved from storage
  /// on first use; `_anon` before anyone has signed in.
  Future<String> _currentScope() async {
    final cached = _scope;
    if (cached != null) return cached;
    final userId =
        await SharedPrefHelper.getString(SharedPrefKeys.userId) as String? ?? '';
    return _scope = userId.isEmpty ? '_anon' : userId;
  }

  /// Points the cache at [userId]'s partition. Call after a successful login so
  /// the first cached write of the session lands in the right place.
  void useScope(String userId) {
    final next = userId.isEmpty ? '_anon' : userId;
    if (_scope == next) return;
    _scope = next;
    _memory.clear();
  }

  Future<Directory?> _directory() async {
    try {
      final root = await _rootDirectory();
      final scoped = Directory('${root.path}/${await _currentScope()}');
      if (!await scoped.exists()) await scoped.create(recursive: true);
      return scoped;
    } catch (e) {
      debugPrint('OfflineCache: cannot resolve cache directory — $e');
      return null;
    }
  }

  Future<Directory> _rootDirectory() async {
    final override = rootOverride;
    if (override != null) return override;
    return _root ??= Directory(
      '${(await getApplicationSupportDirectory()).path}/offline_cache',
    );
  }

  Future<File?> _fileFor(String key) async {
    final dir = await _directory();
    if (dir == null) return null;
    final safe = key.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    return File('${dir.path}/$safe.json');
  }

  // ── Reads ─────────────────────────────────────────────────────────────────

  /// The cached list stored under [key], or null when nothing is cached.
  Future<List<Map<String, dynamic>>?> readList(String key) async {
    final entry = await _read(key);
    final payload = entry?.payload;
    if (payload is! List) return null;
    return payload
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// The cached object stored under [key], or null when nothing is cached.
  Future<Map<String, dynamic>?> readMap(String key) async {
    final entry = await _read(key);
    final payload = entry?.payload;
    if (payload is! Map) return null;
    return Map<String, dynamic>.from(payload);
  }

  /// When [key] was last written, or null if it has never been written (or has
  /// not been read yet this session).
  DateTime? savedAt(String key) => _memory[key]?.savedAt;

  Future<_CacheEntry?> _read(String key) async {
    final remembered = _memory[key];
    if (remembered != null) return remembered;
    try {
      final file = await _fileFor(key);
      if (file == null || !await file.exists()) return null;
      final decoded = json.decode(await file.readAsString());
      if (decoded is! Map) return null;
      final entry = _CacheEntry(
        payload: decoded['payload'],
        savedAt: DateTime.tryParse(decoded['saved_at'] as String? ?? ''),
      );
      return _memory[key] = entry;
    } catch (e) {
      debugPrint('OfflineCache: read of "$key" failed — $e');
      return null;
    }
  }

  // ── Writes ────────────────────────────────────────────────────────────────

  /// Stores [items] under [key], keeping at most [limit] entries.
  Future<void> writeList(
    String key,
    List<Map<String, dynamic>> items, {
    required int limit,
  }) =>
      _write(key, items.take(limit).toList());

  /// Stores [value] under [key].
  Future<void> writeMap(String key, Map<String, dynamic> value) =>
      _write(key, value);

  Future<void> _write(String key, Object payload) async {
    final savedAt = DateTime.now();

    // Encode *first*, and mirror the re-decoded result rather than the object
    // that came in.
    //
    // What a model's `toJson()` returns is not necessarily JSON. With
    // json_serializable's default `explicit_to_json: false`, `Post.toJson()`
    // emits its nested `author`, `likes` and `comments` as **objects**, not
    // maps — `json.encode` fixes that on the way to disk (it calls `toJson()`
    // on anything it can't encode), but a mirror of the original map hands
    // those objects straight back, and `Post.fromJson` throws on
    // `json['author'] as Map<String, dynamic>`.
    //
    // That is exactly what "the cached feed shows up once and then disappears"
    // was: the disk copy was fine all along, but every read served from memory
    // after a successful load threw and was swallowed as "nothing cached".
    // Normalising here makes an in-memory read byte-identical to a read after
    // a restart, for every model, including ones added later.
    final String encoded;
    final Object? normalised;
    try {
      encoded = json.encode({
        'saved_at': savedAt.toIso8601String(),
        'payload': payload,
      });
      normalised = (json.decode(encoded) as Map)['payload'];
    } catch (e) {
      // Nothing is mirrored either: a memory-only entry that no restart could
      // reproduce is worse than no cache at all.
      debugPrint('OfflineCache: "$key" is not JSON-encodable — not cached ($e)');
      return;
    }

    _memory[key] = _CacheEntry(payload: normalised, savedAt: savedAt);
    try {
      final file = await _fileFor(key);
      if (file == null) return;
      await file.writeAsString(encoded);
    } catch (e) {
      // A failed disk write is not worth surfacing — the screen already has the
      // fresh data it was about to cache.
      debugPrint('OfflineCache: write of "$key" failed — $e');
    }
  }

  /// Drops one bucket.
  Future<void> remove(String key) async {
    _memory.remove(key);
    try {
      final file = await _fileFor(key);
      if (file != null && await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Wipes every bucket for every user. Called from the session-end hooks so a
  /// signed-out device keeps nothing of the previous account.
  Future<void> clear() async {
    _memory.clear();
    try {
      final root = await _rootDirectory();
      if (await root.exists()) await root.delete(recursive: true);
    } catch (e) {
      debugPrint('OfflineCache: clear failed — $e');
    }
    _scope = null;
  }
}

class _CacheEntry {
  const _CacheEntry({required this.payload, this.savedAt});

  final Object? payload;
  final DateTime? savedAt;
}
