import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/data/repos/feed_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/posts/post_state.dart';
import 'package:riff/features/home/feed/logic/cubit/likes/like_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_cubit.dart';

class PostCubit extends Cubit<PostState> {
  final LikeCubit _likeCubit;
  final FeedCubit _feedCubit;
  final FeedRepo _feedRepo;

  PostCubit(this._likeCubit, this._feedCubit, this._feedRepo)
      : super(const PostState.initial());

  /// Toggle like/unlike for a post
  Future<void> toggleLike(
    Post post, {
    required Function(bool isLiked, int likeCount) onOptimisticUpdate,
    required Function() onRevert,
    required Function(String error) onError,
  }) async {
    final postId = post.id.toString();
    final currentIsLiked = post.isLiked ?? false;
    final currentLikeCount = int.tryParse(post.likesCount ?? '0') ?? 0;
    final newLikeCount = currentLikeCount + (currentIsLiked ? -1 : 1);
    final newIsLiked = !currentIsLiked;

    // Optimistic update
    onOptimisticUpdate(newIsLiked, newLikeCount);

    try {
      ApiResult<bool> result;
      if (newIsLiked) {
        result = await _likeCubit.likePost(postId);
      } else {
        result = await _likeCubit.unlikePost(postId);
      }

      result.when(
        success: (success) {
          if (success) {
            // Update feed locally
            _feedCubit.updatePostLikeLocally(postId, newIsLiked, newLikeCount);
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
