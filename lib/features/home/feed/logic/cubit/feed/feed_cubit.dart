import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/features/home/feed/data/repos/feed_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_state.dart';
import 'package:riff/core/networks/api_result.dart' hide Success;
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/features/home/feed/data/models/posts_response.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';

class FeedCubit extends Cubit<FeedState> {
  final FeedRepo _feedRepo;

  FeedCubit(this._feedRepo) : super(const FeedState.initial());

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

  Future<void> retryLoadMore() async {
    _lastError = null;
    await getPosts();
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
      _posts.clear();
      _hasMore = true;
      unawaited(loadTrending());
    }

    // For first page show full loading state, for subsequent pages keep current data
    if (page == 1) {
      emit(const FeedState.loading());
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
        if (data.pagination.page >= data.pagination.totalPages) {
          _hasMore = false;
        } else {
          page++;
        }
      },
      failure: (apiErrorModel) {
        _isLoadingMore = false;
        if (page > 1) {
          _lastError = apiErrorModel;
          if (!isClosed && state is Success) emit(state);
        } else {
          if (!isClosed) emit(FeedState.failure(apiErrorModel));
        }
      },
    );
  }
}
