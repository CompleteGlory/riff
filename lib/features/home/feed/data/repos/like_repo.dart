import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_services.dart';

class LikeRepo {
  final ApiService _apiService;

  LikeRepo(this._apiService);

  Future<ApiResult<bool>> likePost(String postId) async {
    try {
      final response = await _apiService.likePost(postId);
      final data = response.data;
      if (data is bool) return ApiResult.success(data);
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
}
