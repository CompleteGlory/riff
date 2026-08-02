import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/cache/cache_keys.dart';
import 'package:riff/core/cache/offline_cache.dart';
import 'package:riff/core/logic/reconnect_refresh.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/profile/data/repos/profile_repo.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState>
    with ReconnectRefresh<ProfileState> {
  final ProfileRepo _repo;
  final OfflineCache _cache;
  List<Post> _posts = [];
  String? _lastUserId;

  /// Whether the posts on screen came from the offline cache. Only the signed-in
  /// user's own posts are cached, so this is never true for anyone else's.
  bool _isShowingCached = false;
  bool get isShowingCached => _isShowingCached;

  /// When the cached copy on screen was written.
  DateTime? get cacheSavedAt => _cache.savedAt(CacheKeys.myPosts);

  ProfileCubit(this._repo, {OfflineCache? cache})
      : _cache = cache ?? OfflineCache.instance,
        super(const ProfileState.initial()) {
    refreshOnReconnect(() {
      final userId = _lastUserId;
      if (_isShowingCached && userId != null) loadUserPosts(userId);
    });
  }

  List<Post> get posts => _posts;

  Future<void> loadUserPosts(String userId) async {
    _lastUserId = userId;
    // Resolved once, up front. The success handler below is a synchronous
    // callback, so it can't await this — and doing the lookup there instead
    // meant the cache write only started a microtask later, which is a race
    // with anything that reads the cache straight afterwards.
    final isMine = await _isMe(userId);
    if (isClosed) return;

    if (_posts.isEmpty) {
      final cached = isMine ? await _readCachedPosts() : null;
      if (isClosed) return;
      if (cached != null && cached.isNotEmpty) {
        _posts = cached;
        _isShowingCached = true;
        emit(ProfileState.success(cached));
      } else {
        emit(const ProfileState.loading());
      }
    }

    final result = await _repo.getUserPosts(userId);
    if (isClosed) return;
    result.when(
      success: (posts) {
        _posts = posts;
        _isShowingCached = false;
        emit(ProfileState.success(posts));
        if (isMine) unawaited(_cachePosts(posts));
      },
      failure: (error) {
        // Cached posts already on screen beat replacing a real profile with an
        // error page.
        if (_posts.isNotEmpty) {
          emit(ProfileState.success(_posts));
          return;
        }
        emit(ProfileState.failure(error.message ?? 'Failed to load posts'));
      },
    );
  }

  // ── Offline cache ───────────────────────────────────────────────────────────

  /// Whether [userId] is the signed-in user, and therefore the one profile
  /// worth keeping a copy of.
  Future<bool> _isMe(String userId) async =>
      (await _cache.readMap(CacheKeys.myProfile))?['id'] == userId;

  Future<List<Post>?> _readCachedPosts() async {
    final raw = await _cache.readList(CacheKeys.myPosts);
    if (raw == null) return null;
    try {
      return raw.map(Post.fromJson).toList();
    } catch (e) {
      debugPrint('ProfileCubit: cached posts unreadable — $e');
      return null;
    }
  }

  Future<void> _cachePosts(List<Post> posts) => _cache.writeList(
        CacheKeys.myPosts,
        posts.map((p) => p.toJson()).toList(),
        limit: CacheKeys.myPostsLimit,
      );

  Future<void> uploadProfileImage(File file) async {
    emit(const ProfileState.imageUploading());
    final result = await _repo.uploadProfileImage(file);
    result.when(
      success: (url) => emit(ProfileState.imageUploadSuccess(url)),
      failure: (error) => emit(
        ProfileState.imageUploadFailure(error.message ?? 'Upload failed'),
      ),
    );
  }
}
