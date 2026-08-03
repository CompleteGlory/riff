import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/cache/cache_keys.dart';
import 'package:riff/core/cache/offline_cache.dart';
import 'package:riff/core/logic/post_deletion.dart';
import 'package:riff/core/logic/post_events.dart';
import 'package:riff/core/logic/reconnect_refresh.dart';
import 'package:riff/features/home/feed/data/repos/feed_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_state.dart';
import 'package:riff/core/networks/api_result.dart' hide Success;
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/features/home/feed/data/models/pagination.dart';
import 'package:riff/features/home/feed/data/models/posts_response.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';

class FeedCubit extends Cubit<FeedState> with ReconnectRefresh<FeedState> {
  final FeedRepo _feedRepo;
  final OfflineCache _cache;

  FeedCubit(this._feedRepo, {OfflineCache? cache})
      : _cache = cache ?? OfflineCache.instance,
        super(const FeedState.initial()) {
    // Walking back into signal should not require a pull-to-refresh.
    refreshOnReconnect(() {
      // Only when the list on screen is known to be behind — either it came out
      // of the cache, or the last fetch failed. Refreshing an up-to-date feed
      // would reorder it under the user for no reason.
      if (_isShowingCached || _lastLoadFailed) getPosts(refresh: true);
    });
    _deletionSub = PostEvents.deletions.listen(removePostLocally);
  }

  StreamSubscription<String>? _deletionSub;

  /// Broadcast bus used to tell the currently-mounted feed to reload — e.g. after
  /// a new post finishes uploading. FeedCubit is a factory (each FeedScreen owns
  /// its own instance), so callers can't reach "the" instance directly; the
  /// mounted FeedScreen listens to this and refreshes itself.
  static final _refreshBus = StreamController<void>.broadcast();
  static Stream<void> get refreshRequests => _refreshBus.stream;
  static void requestRefresh() {
    if (!_refreshBus.isClosed) _refreshBus.add(null);
  }

  int page = 1;
  final int limit = 4;

  final List<Post> _posts = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;

  Post? trendingPost;

  Future<void> loadTrending() async {
    final result = await _feedRepo.getTrendingPost();
    result.whenOrNull(success: (post) => trendingPost = post);
  }

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  ApiErrorModel? _lastError;
  ApiErrorModel? get lastError => _lastError;

  bool _isShowingCached = false;

  /// Whether the most recent fetch failed, so a reconnect knows the list on
  /// screen is stale even when it was never restored from cache.
  bool _lastLoadFailed = false;

  /// True while the list on screen came out of the offline cache rather than
  /// the API. The feed reads this to show the "saved earlier" strip — the state
  /// itself stays a plain `success` so nothing downstream has to special-case
  /// a third kind of loaded feed.
  bool get isShowingCached => _isShowingCached;

  /// When the cached copy currently on screen was written.
  DateTime? get cacheSavedAt => _cache.savedAt(CacheKeys.feedPosts);

  Future<void> retryLoadMore() async {
    _lastError = null;
    await getPosts();
  }

  /// Drop a deleted post from the feed, and mark any share of it as quoting a
  /// post that no longer exists.
  ///
  /// Driven by [PostEvents.deletions] so a delete performed anywhere — the
  /// profile, reels, the post detail screen — takes effect here immediately
  /// instead of at the next refresh.
  void removePostLocally(String postId) {
    if (trendingPost?.id.toString() == postId) trendingPost = null;

    // Unconditional, and read-modify-write against the cache rather than a
    // rewrite from `_posts`: the cached copy is the first page, this cubit may
    // hold several pages or none at all, and either way the post must not come
    // back on the next offline start.
    unawaited(_pruneCache(postId));

    final updated = applyPostDeletion(_posts, postId);
    // Nothing in this list referenced the deleted post.
    if (identical(updated, _posts)) return;

    _posts
      ..clear()
      ..addAll(updated);

    if (!isClosed && state is Success) {
      final currentState = state as Success;
      emit(FeedState.success(PostsResponse(
        data: List<Post>.from(_posts),
        pagination: currentState.data.pagination,
      )));
    }
  }

  Future<void> _pruneCache(String postId) async {
    final cached = await _readCachedPosts();
    if (cached == null || cached.isEmpty) return;
    final updated = applyPostDeletion(cached, postId);
    if (identical(updated, cached)) return;
    await _cachePosts(updated);
  }

  /// Update a post locally in the posts list
  void updatePostLocally(
    String postId,
    String newContent,
    List<String>? newMedia,
  ) {
    final postIndex = _posts.indexWhere((post) => post.id.toString() == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final updatedPost = Post(
        id: post.id,
        author: post.author,
        content: newContent,
        createdAt: post.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        isLiked: post.isLiked,
        likesCount: post.likesCount,
        media: newMedia,
        authorId: post.authorId,
        likes: post.likes,
        comments: post.comments,
      );
      _posts[postIndex] = updatedPost;
      if (state is Success) {
        final currentState = state as Success;
        emit(
          FeedState.success(
            PostsResponse(
              data: List<Post>.from(_posts),
              pagination: currentState.data.pagination,
            ),
          ),
        );
      }
    }
  }

  /// Update a post's like status and likes count locally
  void updatePostLikeLocally(String postId, bool isLiked, int likesCount) {
    final postIndex = _posts.indexWhere((post) => post.id.toString() == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final updatedPost = Post(
        id: post.id,
        author: post.author,
        content: post.content,
        createdAt: post.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        isLiked: isLiked,
        likesCount: likesCount.toString(),
        media: post.media,
        authorId: post.authorId,
        likes: post.likes,
        comments: post.comments,
      );
      _posts[postIndex] = updatedPost;
      if (state is Success) {
        final currentState = state as Success;
        emit(
          FeedState.success(
            PostsResponse(
              data: List<Post>.from(_posts),
              pagination: currentState.data.pagination,
            ),
          ),
        );
      }
    }
  }

  /// Add a comment to a post locally and emit updated feed state
  void addCommentLocally(String postId, Comment comment) {
    final postIndex = _posts.indexWhere((post) => post.id.toString() == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final existing = post.comments ?? [];
      final updatedComments = List<Comment>.from(existing)..insert(0, comment);
      final updatedPost = Post(
        id: post.id,
        author: post.author,
        content: post.content,
        createdAt: post.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        isLiked: post.isLiked,
        likesCount: post.likesCount,
        media: post.media,
        authorId: post.authorId,
        likes: post.likes,
        comments: updatedComments,
      );
      _posts[postIndex] = updatedPost;
      if (state is Success) {
        final currentState = state as Success;
        emit(
          FeedState.success(
            PostsResponse(
              data: List<Post>.from(_posts),
              pagination: currentState.data.pagination,
            ),
          ),
        );
      }
    }
  }

  /// Fetch posts with pagination support
  Future<void> getPosts({bool refresh = false}) async {
    if (_isLoadingMore) return;

    if (refresh) {
      page = 1;
      _hasMore = true;
      // Deliberately *not* clearing _posts here. The list is cleared when the
      // replacement actually arrives, so a pull-to-refresh — especially one on
      // a connection that is about to fail — doesn't blank the feed the user is
      // reading and then put it straight back.
      unawaited(loadTrending());
    }

    // For first page show full loading state, for subsequent pages keep current data
    if (page == 1) {
      if (_posts.isNotEmpty) {
        // Something is already on screen; leave it there while page 1 reloads.
      } else {
        // A cached feed beats a shimmer: on a dead connection it is the only
        // thing the user will get, and on a live one it is replaced before it
        // registers.
        final cached = await _readCachedPosts();
        if (isClosed) return;
        if (cached != null && cached.isNotEmpty) {
          _posts.addAll(cached);
          _isShowingCached = true;
          emit(FeedState.success(PostsResponse(
            data: List<Post>.from(_posts),
            pagination: _cachedPagination(_posts.length),
          )));
        } else {
          emit(const FeedState.loading());
        }
      }
    } else {
      _isLoadingMore = true;
      // keep current success state so UI can show existing posts
      if (state is Success) emit(state);
    }

    final response = await _feedRepo.getPosts(page, limit);

    // Guard: cubit may have been closed while the request was in-flight
    // (e.g. user navigated away and the BlocProvider was disposed).
    if (isClosed) return;

    response.when(
      success: (PostsResponse data) {
        // The first live page replaces whatever was on screen — cached posts,
        // or the previous session's — so a deleted or reordered post doesn't
        // linger underneath the fresh ones.
        if (page == 1) _posts.clear();
        _isShowingCached = false;
        _lastLoadFailed = false;
        _lastError = null;

        // append new posts but avoid duplicates
        final newPosts = data.data
            .where((p) => !_posts.any((existing) => existing.id == p.id))
            .toList();
        _posts.addAll(newPosts);

        final combined = PostsResponse(
          data: List<Post>.from(_posts),
          pagination: data.pagination,
        );

        if (!isClosed) emit(FeedState.success(combined));

        // update paging
        _isLoadingMore = false;
        final wasFirstPage = data.pagination.page <= 1;
        if (data.pagination.page >= data.pagination.totalPages) {
          _hasMore = false;
        } else {
          page++;
        }
        if (wasFirstPage) unawaited(_cachePosts(data.data));
      },
      failure: (apiErrorModel) {
        _isLoadingMore = false;
        _lastLoadFailed = true;
        if (page > 1) {
          _lastError = apiErrorModel;
          if (!isClosed && state is Success) emit(state);
        } else if (_posts.isNotEmpty) {
          // Leave the posts where they are — an error page over real (if stale)
          // content is strictly worse than the content plus the offline strip,
          // which is what the screen already shows. No pagination error is
          // recorded: this was page 1, and the "couldn't load more" footer at
          // the bottom of the list would be describing the wrong thing.
          if (!isClosed && state is Success) emit(state);
        } else {
          if (!isClosed) emit(FeedState.failure(apiErrorModel));
        }
      },
    );
  }

  // ── Offline cache ─────────────────────────────────────────────────────────

  Pagination _cachedPagination(int count) =>
      Pagination(page: 1, limit: limit, total: count, totalPages: 1);

  Future<List<Post>?> _readCachedPosts() async {
    final raw = await _cache.readList(CacheKeys.feedPosts);
    if (raw == null) return null;
    try {
      return raw.map(Post.fromJson).toList();
    } catch (e) {
      debugPrint('FeedCubit: cached feed unreadable — $e');
      return null;
    }
  }

  Future<void> _cachePosts(List<Post> posts) => _cache.writeList(
        CacheKeys.feedPosts,
        posts.map((p) => p.toJson()).toList(),
        limit: CacheKeys.feedPostsLimit,
      );

  @override
  Future<void> close() {
    _deletionSub?.cancel();
    return super.close();
  }
}
