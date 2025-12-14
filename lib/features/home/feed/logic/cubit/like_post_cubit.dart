import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/repos/feed_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/like_post_state.dart';

class LikePostCubit extends Cubit<LikePostState> {
  final FeedRepo _feedRepo;

  LikePostCubit(this._feedRepo) : super(const LikePostState.initial());

  /// Likes/unlikes a post using the FeedRepo and updates FeedCubit on success.
  /// Returns the ApiResult so callers (UI) can await and react if needed.
  Future<ApiResult<bool>> likePost(String postId) async {
    emit(const LikePostState.loading());

    final response = await _feedRepo.likePost(postId);

    response.when(
      success: (liked) {
        emit(LikePostState.success(liked));
      },
      failure: (apiError) {
        emit(LikePostState.failure(apiError));
      },
    );

    return response;
  }

  Future<ApiResult<bool>> unlikePost(String postId) async {
    emit(const LikePostState.loading());

    final response = await _feedRepo.unlikePost(postId);

    response.when(
      success: (ok) {
        emit(LikePostState.success(ok));
      },
      failure: (apiError) {
        emit(LikePostState.failure(apiError));
      },
    );

    return response;
  }
}
