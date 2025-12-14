import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/home/feed/data/models/author.dart';
import 'package:riff/features/home/feed/data/models/posts_response.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';
import 'package:riff/features/home/feed/data/models/create_comment_request_model.dart';

class FeedRepo {
  final ApiService _apiService;

  FeedRepo(this._apiService);

  Future<ApiResult<PostsResponse>> getPosts(int page, int limit) async {
    try {
      final response = await _apiService.getPosts(page, limit);
      return ApiResult.success(response);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<bool>> likePost(String postId) async {
    try {
      final response = await _apiService.likePost(postId);

      // The backend may return a boolean `true` on success (text/html),
      // or a Post object. Normalize to a boolean success flag.
      final data = response.data;
      if (data is bool) {
        return ApiResult.success(data);
      }

      // If the API returned an object resembling a Post, treat as success.
      // (We don't parse the full Post here; UI already applies optimistic update.)
      return ApiResult.success(true);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<bool>> unlikePost(String postId) async {
    try {
      final response = await _apiService.unlikePost(postId);

      final data = response.data;
      if (data is bool) return ApiResult.success(data);
      return ApiResult.success(true);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<Comment>> createComment(
    String postId,
    CreateCommentRequestModel body,
  ) async {
    try {
      final response = await _apiService.createComment(postId, body);
      final data = response.data;

      // ✅ CASE 1: Retrofit already parsed it
      if (data is Comment) {
        return ApiResult.success(_attachCurrentUserAsAuthor(data));
      }

      // ✅ CASE 2: Raw JSON map
      if (data is Map<String, dynamic>) {
        final comment = Comment.fromJson(data as Map<String, dynamic>);
        return ApiResult.success(_attachCurrentUserAsAuthor(comment));
      }

      // ❌ Unexpected shape
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
      ),
    );
  }

  Future<ApiResult<List<Comment>>> getPostComments(String postId) async {
  try {
    final response = await _apiService.getPostComments(postId);
    final data = response.data;

    if (data is List) {
      final comments = data.map<Comment>((e) {
        if (e is Comment) {
          return e;
        }
        if (e is Map<String, dynamic>) {
          return Comment.fromJson(e as Map<String, dynamic>);
        }
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

}
