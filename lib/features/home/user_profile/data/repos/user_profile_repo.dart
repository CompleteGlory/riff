import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/user_profile/data/models/user_profile_model.dart';

class UserProfileRepo {
  final ApiService _apiService;

  UserProfileRepo(this._apiService);

  Future<ApiResult<UserProfileModel>> getUserProfile(String userId) async {
    try {
      final response = await _apiService.getUserById(userId);
      final model = UserProfileModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return ApiResult.success(model);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<List<Post>>> getUserPosts(String userId) async {
    try {
      final response = await _apiService.getUserPosts(userId, 1, 100);
      return ApiResult.success(response.data);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}
