// DEPRECATED — LikeCubit is unused. PostCubit consumes LikeRepo directly.
// This class is kept to avoid build_runner errors; do not use it.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/repos/like_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/likes/like_state.dart';

class LikeCubit extends Cubit<LikePostState> {
  final LikeRepo _likeRepo;

  LikeCubit(this._likeRepo) : super(const LikePostState.initial());

  Future<void> likePost(String postId) async {
    emit(const LikePostState.loading());
    final result = await _likeRepo.likePost(postId);
    result.when(
      success: (_) => emit(const LikePostState.success(true)),
      failure: (err) => emit(LikePostState.failure(err)),
    );
  }

  Future<void> unlikePost(String postId) async {
    emit(const LikePostState.loading());
    final result = await _likeRepo.unlikePost(postId);
    result.when(
      success: (_) => emit(const LikePostState.success(false)),
      failure: (err) => emit(LikePostState.failure(err)),
    );
  }
}
