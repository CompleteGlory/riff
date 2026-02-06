import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/repos/like_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/likes/like_state.dart';

class LikePostCubit extends Cubit<LikePostState> {
  final LikeRepo _likeRepo;

  LikePostCubit(this._likeRepo) : super(const LikePostState.initial());

  /// Likes/unlikes a post using the LikeRepo and updates FeedCubit on success.
  /// Returns the ApiResult so callers (UI) can await and react if needed.
  Future<ApiResult<bool>> likePost(String postId) async {
    emit(const LikePostState.loading());

    final response = await _likeRepo.likePost(postId);

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

    final response = await _likeRepo.unlikePost(postId);

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
