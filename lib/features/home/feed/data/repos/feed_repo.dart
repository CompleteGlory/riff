import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/data/models/posts_response.dart';

class FeedRepo {
  final ApiService _apiService;

  FeedRepo(this._apiService);

  Future<ApiResult<Post>> getPostById(int postId) async {
    try {
      final response = await _apiService.getPostById(postId);
      return ApiResult.success(
          Post.fromJson(response.data as Map<String, dynamic>));
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<PostsResponse>> getPosts(int page, int limit) async {
    try {
      final response = await _apiService.getPosts(page, limit);
      return ApiResult.success(response);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<Post>> sharePost(String postId, {String? caption}) async {
    try {
      final response = await _apiService.sharePost(
        postId,
        {'content': caption ?? ''},
      );
      return ApiResult.success(response);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<void> recordView(int postId) async {
    try {
      await _apiService.recordView(postId);
    } catch (_) {
      // fire-and-forget — silently ignore errors
    }
  }

  Future<ApiResult<Post?>> getTrendingPost() async {
    try {
      final response = await _apiService.getTrendingPost();
      if (response.data == null) return const ApiResult.success(null);
      final post = Post.fromJson(response.data as Map<String, dynamic>);
      return ApiResult.success(post);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}
