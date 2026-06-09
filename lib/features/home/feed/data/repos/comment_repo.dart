import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';
import 'package:riff/features/home/feed/data/models/create_comment_request_model.dart';
import 'package:riff/features/home/feed/data/models/author.dart';
import 'package:riff/core/helpers/constants.dart';

class CommentRepo {
  final ApiService _apiService;

  CommentRepo(this._apiService);

  Future<ApiResult<Comment>> createComment(
    String postId,
    CreateCommentRequestModel body,
  ) async {
    try {
      final response = await _apiService.createComment(postId, body);
      final data = response.data;

      if (data is Comment) {
        return ApiResult.success(_attachCurrentUserAsAuthor(data));
      }

      if (data is Map<String, dynamic>) {
        final comment = Comment.fromJson(data as Map<String, dynamic>);
        return ApiResult.success(_attachCurrentUserAsAuthor(comment));
      }

      return ApiResult.failure(
        ApiErrorHandler.handle(Exception('Invalid createComment response')),
      );
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Comment _attachCurrentUserAsAuthor(Comment comment) {
    if (comment.author != null) return comment;

    return Comment(
      id: comment.id,
      content: comment.content,
      createdAt: comment.createdAt,
      author: Author(
        id: SharedPrefHelper.getString(SharedPrefKeys.userId).toString(),
        fullName: 'You',
        username: '',
      ), isLiked: false,
    );
  }

  Future<ApiResult<List<Comment>>> getPostComments(String postId) async {
    try {
      final response = await _apiService.getPostComments(postId);
      final data = response.data;

      if (data is List) {
        final comments = data.map<Comment>((e) {
          if (e is Comment) return e;
          if (e is Map<String, dynamic>) return Comment.fromJson(e as Map<String, dynamic>);
          throw Exception('Invalid comment item');
        }).toList();

        return ApiResult.success(comments);
      }

      return ApiResult.failure(
        ApiErrorHandler.handle(Exception('Invalid comments response')),
      );
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<String>> updateComment(
    String commentId,
    CreateCommentRequestModel body,
  ) async {
    try {
      final response = await _apiService.updateComment(commentId, body);
      final data = response.data;

      if (data is Comment) return ApiResult.success("success");
      if (data is Map<String, dynamic>) {
        return ApiResult.success("success");
      }

      return ApiResult.failure(
        ApiErrorHandler.handle(Exception('Invalid updateComment response')),
      );
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<bool>> deleteComment(String commentId) async {
    try {
      await _apiService.deleteComment(commentId);
      return ApiResult.success(true);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<bool>> likeComment(String commentId) async {
    try {
      await _apiService.likeComment(commentId);
      return ApiResult.success(true);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<bool>> unlikeComment(String commentId) async {
    try {
      await _apiService.unlikeComment(commentId);
      return ApiResult.success(true);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}
