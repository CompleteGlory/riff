import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/cache/cache_keys.dart';
import 'package:riff/core/cache/offline_cache.dart';
import 'package:riff/core/logic/post_deletion.dart';
import 'package:riff/core/logic/post_events.dart';
import 'package:riff/core/logic/reconnect_refresh.dart';
import 'package:riff/core/networks/connectivity_service.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/search/data/repos/search_repo.dart';
import 'package:riff/features/home/search/logic/search_state.dart';

class SearchCubit extends Cubit<SearchState> with ReconnectRefresh<SearchState> {
  final SearchRepo _repo;
  final OfflineCache _cache;
  Timer? _debounce;

  SearchCubit(this._repo, {OfflineCache? cache})
      : _cache = cache ?? OfflineCache.instance,
        super(SearchInitial()) {
    refreshOnReconnect(() {
      if (_isShowingCached) loadDiscover();
    });
    _deletionSub = PostEvents.deletions.listen(removePostLocally);
  }

  StreamSubscription<String>? _deletionSub;

  /// Drop a deleted post from discover or the current search results, and mark
  /// any share of it as quoting a post that no longer exists.
  void removePostLocally(String postId) {
    final current = state;
    if (current is SearchDiscoverLoaded) {
      final updated = applyPostDeletion(current.posts, postId);
      if (!identical(updated, current.posts) && !isClosed) {
        emit(SearchDiscoverLoaded(
          posts: updated,
          activeGenre: current.activeGenre,
          activeInstrument: current.activeInstrument,
          isLoadingPosts: current.isLoadingPosts,
        ));
      }
    } else if (current is SearchResultsLoaded) {
      final updated = applyPostDeletion(current.posts, postId);
      if (!identical(updated, current.posts) && !isClosed) {
        emit(SearchResultsLoaded(
          users: current.users,
          posts: updated,
          query: current.query,
        ));
      }
    }
    unawaited(_pruneCache(postId));
  }

  /// Discover is cached unfiltered, so prune the stored copy directly rather
  /// than writing back whatever filtered list happens to be on screen.
  Future<void> _pruneCache(String postId) async {
    final cached = await _readCachedPosts();
    if (cached == null || cached.isEmpty) return;
    final updated = applyPostDeletion(cached, postId);
    if (identical(updated, cached)) return;
    await _cachePosts(updated);
  }

  bool _isShowingCached = false;

  /// True while discover is showing posts restored from the offline cache.
  bool get isShowingCached => _isShowingCached;

  /// When the cached discover posts were written.
  DateTime? get cacheSavedAt => _cache.savedAt(CacheKeys.discoverPosts);

  /// Called on screen init — loads personalised discover feed
  Future<void> loadDiscover({String? genre, String? instrument}) async {
    final currentState = state;
    if (currentState is SearchDiscoverLoaded) {
      emit(
        SearchDiscoverLoaded(
          posts: currentState.posts,
          activeGenre: genre,
          activeInstrument: instrument,
          isLoadingPosts: true,
        ),
      );
    } else {
      // An unfiltered discover is exactly what the cache holds, so it can stand
      // in while the request runs. A filtered one can't — the cached posts were
      // never selected for that genre, and pretending otherwise would show the
      // user the wrong answer to a question they explicitly asked.
      final cached = (genre == null && instrument == null)
          ? await _readCachedPosts()
          : null;
      if (isClosed) return;
      if (cached != null && cached.isNotEmpty) {
        _isShowingCached = true;
        emit(SearchDiscoverLoaded(posts: cached, isLoadingPosts: true));
      } else {
        emit(SearchLoading());
      }
    }
    try {
      final posts = await _repo.discoverPosts(
        genre: genre,
        instrument: instrument,
      );
      if (isClosed) return;
      _isShowingCached = false;
      emit(
        SearchDiscoverLoaded(
          posts: posts,
          activeGenre: genre,
          activeInstrument: instrument,
        ),
      );
      if (genre == null && instrument == null) unawaited(_cachePosts(posts));
    } catch (e) {
      if (isClosed) return;
      final showing = state;
      // Keep cached posts on screen rather than replacing them with an error.
      if (showing is SearchDiscoverLoaded && showing.posts.isNotEmpty) {
        emit(SearchDiscoverLoaded(
          posts: showing.posts,
          activeGenre: showing.activeGenre,
          activeInstrument: showing.activeInstrument,
        ));
        return;
      }
      emit(SearchError(e.toString()));
    }
  }

  /// Called on every keystroke — debounced 400 ms
  void onQueryChanged(String q) {
    _debounce?.cancel();

    if (q.trim().isEmpty) {
      loadDiscover();
      return;
    }

    // Searching is inherently a live question; there is nothing sensible to
    // serve from cache, so say so up front instead of spinning for the timeout.
    if (ConnectivityService.instance.isOffline) {
      emit(SearchOffline(q));
      return;
    }

    emit(SearchLoading());

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final users = await _repo.searchUsers(q);
        final posts = await _repo.searchPosts(q);
        if (!isClosed) {
          emit(SearchResultsLoaded(users: users, posts: posts, query: q));
        }
      } catch (e) {
        if (isClosed) return;
        emit(ConnectivityService.instance.isOffline
            ? SearchOffline(q)
            : SearchError(e.toString()));
      }
    });
  }

  // ── Offline cache ───────────────────────────────────────────────────────────

  Future<List<Post>?> _readCachedPosts() async {
    final raw = await _cache.readList(CacheKeys.discoverPosts);
    if (raw == null) return null;
    try {
      return raw.map(Post.fromJson).toList();
    } catch (e) {
      debugPrint('SearchCubit: cached discover posts unreadable — $e');
      return null;
    }
  }

  Future<void> _cachePosts(List<Post> posts) => _cache.writeList(
        CacheKeys.discoverPosts,
        posts.map((p) => p.toJson()).toList(),
        limit: CacheKeys.discoverPostsLimit,
      );

  @override
  Future<void> close() {
    _debounce?.cancel();
    _deletionSub?.cancel();
    return super.close();
  }
}
