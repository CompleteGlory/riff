import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/home/follow/data/models/follow_user.dart';

class LikeRepo {
  final ApiService _apiService;
  final Dio _dio;

  LikeRepo(this._apiService, this._dio);

  /// The users who liked [postId].
  ///
  /// Returns [FollowUser] rather than a like-specific model: the endpoint is
  /// shaped exactly like `/users/:id/followers` on purpose, so this list reuses
  /// the same rows, the same follow buttons and the same screen.
  Future<ApiResult<List<FollowUser>>> getPostLikers(int postId) async {
    try {
      final res = await _dio.get(ApiConstants.postLikes(postId));
      final list = (res.data as List<dynamic>)
          .map((e) => FollowUser.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(list);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

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
