import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/data/repos/feed_repo.dart';
import 'package:riff/features/home/feed/data/repos/like_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/posts/post_state.dart';

class PostCubit extends Cubit<PostState> {
  final LikeRepo _likeRepo;
  final FeedRepo _feedRepo;

  PostCubit(this._likeRepo, this._feedRepo) : super(const PostState.initial());

  /// Toggle like/unlike for a post.
  ///
  /// [onOptimisticUpdate] fires synchronously, before any network work, so the
  /// caller can repaint on the current frame. On failure [onRevert] restores
  /// the previous state.
  ///
  /// [currentIsLiked] / [currentLikeCount] are what the caller has on screen.
  /// They default to the values on [post], which is only ever the server's
  /// answer from when the feed loaded — nothing writes back to the model, so a
  /// caller that toggles twice without passing its own state recomputes from
  /// the same stale value and sends a second *like* instead of an unlike.
  Future<void> toggleLike(
    Post post, {
    bool? currentIsLiked,
    int? currentLikeCount,
    required Function(bool isLiked, int likeCount) onOptimisticUpdate,
    required Function() onRevert,
    required Function(String error) onError,
  }) async {
    final postId = post.id.toString();
    final isLiked = currentIsLiked ?? post.isLiked ?? false;
    final likeCount =
        currentLikeCount ?? int.tryParse(post.likesCount ?? '0') ?? 0;
    final newLikeCount = likeCount + (isLiked ? -1 : 1);
    final newIsLiked = !isLiked;

    onOptimisticUpdate(newIsLiked, newLikeCount);

    try {
      final ApiResult<bool> result = newIsLiked
          ? await _likeRepo.likePost(postId)
          : await _likeRepo.unlikePost(postId);

      result.when(
        success: (success) {
          if (success) {
            emit(PostState.likeSuccess(postId, newIsLiked, newLikeCount));
          } else {
            onRevert();
            onError('Failed to update like');
            emit(PostState.likeError('Failed to update like'));
          }
        },
        failure: (error) {
          onRevert();
          onError(error.message ?? 'Failed to update like');
          emit(PostState.likeError(error.message ?? 'Failed to update like'));
        },
      );
    } catch (e) {
      onRevert();
      onError('Unexpected error');
      emit(PostState.likeError('Unexpected error'));
    }
  }

  /// Share a post via the backend API with an optional caption
  Future<void> sharePost(Post post, {String? caption}) async {
    final result =
        await _feedRepo.sharePost(post.id.toString(), caption: caption);
    result.when(
      success: (_) => emit(const PostState.shareSuccess()),
      failure: (error) =>
          emit(PostState.likeError(error.message ?? 'Failed to share post')),
    );
  }
}
