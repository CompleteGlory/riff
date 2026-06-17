import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';
import 'package:riff/features/home/feed/data/models/create_comment_request_model.dart';
import 'package:riff/features/home/feed/data/repos/comment_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/comments/comment_state.dart';

class CommentCubit extends Cubit<CommentState> {
  final CommentRepo _commentRepo;

  CommentCubit(this._commentRepo) : super(const CommentState.initial());

  /// Fetch a single comment by ID (returns raw map with nested relations)
  Future<ApiResult<Map<String, dynamic>>> getComment(int commentId) async {
    return await _commentRepo.getCommentById(commentId);
  }

  /// Create a comment on a post
  Future<ApiResult<Comment>> createComment(
    String postId,
    String content, {
    int? parentCommentId,
  }) async {
    try {
      final body = CreateCommentRequestModel(
        content: content,
        parentCommentId: parentCommentId,
      );
      final response = await _commentRepo.createComment(postId, body);
      return response;
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  /// Get all comments for a post
  Future<ApiResult<List<Comment>>> getPostComments(String postId) async {
    emit(const CommentState.loading());

    try {
      final response = await _commentRepo.getPostComments(postId);
      response.when(
        success: (comments) {
          emit(CommentState.success(comments));
        },
        failure: (error) {
          emit(CommentState.failure(error));
        },
      );
      return response;
    } catch (e) {
      final error = ApiErrorHandler.handle(e);
      emit(CommentState.failure(error));
      return ApiResult.failure(error);
    }
  }

  /// Update an existing comment
  Future<ApiResult<String>> updateComment(
    String commentId,
    String content,
  ) async {
    final body = CreateCommentRequestModel(content: content);
    return await _commentRepo.updateComment(commentId, body);
  }

  /// Delete a comment
  Future<ApiResult<bool>> deleteComment(String commentId) async {
    return await _commentRepo.deleteComment(commentId);
  }

  /// Like a comment
  Future<ApiResult<bool>> likeComment(String commentId) async {
    return await _commentRepo.likeComment(commentId);
  }

  /// Unlike a comment
  Future<ApiResult<bool>> unlikeComment(String commentId) async {
    return await _commentRepo.unlikeComment(commentId);
  }
}
