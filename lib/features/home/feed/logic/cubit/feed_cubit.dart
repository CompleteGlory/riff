import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/features/home/feed/data/repos/feed_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/feed_state.dart';
import 'package:riff/core/networks/api_result.dart' hide Success;
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/features/home/feed/data/models/posts_response.dart';

import '../../data/models/post.dart';

class FeedCubit extends Cubit<FeedState> {
  final FeedRepo _feedRepo;

  FeedCubit(this._feedRepo) : super(const FeedState.initial());

  int page = 1;
  final int limit = 10;

  final List<Post> _posts = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  ApiErrorModel? _lastError;
  ApiErrorModel? get lastError => _lastError;

  Future<void> retryLoadMore() async {
    _lastError = null;
    await getPosts();
  }

  Future<void> getPosts({bool refresh = false}) async {
    if (_isLoadingMore) return;

    if (refresh) {
      page = 1;
      _posts.clear();
      _hasMore = true;
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

    response.when(
      success: (PostsResponse data) {
        // append new posts
        _posts.addAll(data.data);

        final combined = PostsResponse(data: List<Post>.from(_posts), pagination: data.pagination);

        emit(FeedState.success(combined));

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
          if (state is Success) emit(state);
        } else {
          emit(FeedState.failure(apiErrorModel));
        }
      },
    );
  }
}
