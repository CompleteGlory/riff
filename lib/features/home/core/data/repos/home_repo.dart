import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/home/profile/UI/profile_screen.dart';

class HomeRepo {
  final ApiService _apiService;
  HomeRepo(this._apiService);

  Future<ApiResult<UserProfile>> getMe() async {
    try {
      final response = await _apiService.getUser();
      final data = response.data as Map<String, dynamic>;
      return ApiResult.success(UserProfile.fromJson(data));
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}