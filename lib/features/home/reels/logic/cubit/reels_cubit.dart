import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/cache/cache_keys.dart';
import 'package:riff/core/cache/offline_cache.dart';
import 'package:riff/core/logic/reconnect_refresh.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/reels/data/repos/reels_repo.dart';
import 'package:riff/features/home/reels/logic/cubit/reels_state.dart';

class ReelsCubit extends Cubit<ReelsState> with ReconnectRefresh<ReelsState> {
  final ReelsRepo _reelsRepo;
  final OfflineCache _cache;

  ReelsCubit(this._reelsRepo, {OfflineCache? cache})
      : _cache = cache ?? OfflineCache.instance,
        super(const ReelsInitial()) {
    refreshOnReconnect(() {
      if (_isShowingCached) loadReels(refresh: true);
    });
  }

  int _page = 1;
  final int _limit = 10;
  final List<Post> _reels = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isShowingCached = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// True while the reels on screen came from the offline cache.
  bool get isShowingCached => _isShowingCached;

  /// When the cached copy on screen was written.
  DateTime? get cacheSavedAt => _cache.savedAt(CacheKeys.reels);

  Future<void> loadReels({bool refresh = false}) async {
    if (_isLoadingMore) return;
    if (!refresh && !_hasMore) return; // nothing more to fetch

    if (refresh) {
      _page = 1;
      _reels.clear();
      _hasMore = true;
      emit(const ReelsLoading());
    } else if (_page == 1) {
      // Show the last batch of reels instead of a spinner while the request is
      // out — and, if it never comes back, instead of an error page.
      final cached = await _readCachedReels();
      if (isClosed) return;
      if (cached != null && cached.isNotEmpty) {
        _reels
          ..clear()
          ..addAll(cached);
        _isShowingCached = true;
        emit(ReelsSuccess(reels: List.from(_reels), hasMore: true));
      } else {
        emit(const ReelsLoading());
      }
    } else {
      _isLoadingMore = true;
      emit(ReelsLoadingMore(reels: List.from(_reels)));
    }

    final result = await _reelsRepo.getReels(_page, _limit);
    if (isClosed) return;

    result.when(
      success: (data) {
        // The live first page replaces the cached one rather than stacking on
        // top of it, so a reel that has since been taken down disappears.
        if (_page == 1) _reels.clear();
        _isShowingCached = false;

        final newReels = data.data
            .where((r) => !_reels.any((e) => e.id == r.id))
            .toList();
        _reels.addAll(newReels);
        _isLoadingMore = false;
        final wasFirstPage = _page == 1;
        _page++;
        _hasMore = _page <= data.pagination.totalPages;
        emit(ReelsSuccess(reels: List.from(_reels), hasMore: _hasMore));
        if (wasFirstPage) unawaited(_cacheReels(data.data));
      },
      failure: (err) {
        _isLoadingMore = false;
        // Cached reels already on screen beat replacing them with an error.
        if (_reels.isNotEmpty) {
          emit(ReelsSuccess(reels: List.from(_reels), hasMore: _hasMore));
          return;
        }
        emit(ReelsFailure(err.message ?? 'Failed to load reels'));
      },
    );
  }

  // ── Offline cache ───────────────────────────────────────────────────────────

  Future<List<Post>?> _readCachedReels() async {
    final raw = await _cache.readList(CacheKeys.reels);
    if (raw == null) return null;
    try {
      return raw.map(Post.fromJson).toList();
    } catch (e) {
      debugPrint('ReelsCubit: cached reels unreadable — $e');
      return null;
    }
  }

  Future<void> _cacheReels(List<Post> reels) => _cache.writeList(
        CacheKeys.reels,
        reels.map((r) => r.toJson()).toList(),
        limit: CacheKeys.reelsLimit,
      );
}
