import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/home/feed/data/models/posts_response.dart';

class FeedRepo {
  final ApiService _apiService;

  FeedRepo(this._apiService);

  Future<ApiResult<PostsResponse>> getPosts(int page, int limit) async {
    // TEMPORARILY REMOVED try-catch TO UNMASK THE ERROR
    // The raw exception (e.g., TypeError) will now crash the app,
    // and the console will show the full stack trace, pointing to the exact model field.
    final response = await _apiService.getPosts(page, limit);
    return ApiResult.success(response);
    
    /* Original handled code:
    try {
      final response = await _apiService.getPosts(page, limit);
      return ApiResult.success(response);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
    */
  }
}