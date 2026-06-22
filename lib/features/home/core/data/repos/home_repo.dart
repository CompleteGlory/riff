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

  /// Returns true if [username] is available for the current user.
  Future<ApiResult<bool>> checkUsername(String username) async {
    try {
      final response = await _apiService.checkUsername(username);
      final data = response.data as Map<String, dynamic>;
      return ApiResult.success(data['available'] as bool);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  /// Changes the user's password after verifying the old one.
  Future<ApiResult<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.changePassword({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  /// Updates fullName, username, email, genres, and/or instruments for the current user.
  Future<ApiResult<void>> updateProfile({
    String? fullName,
    String? username,
    String? email,
    List<String>? genres,
    List<String>? instruments,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (username != null) body['username'] = username;
      if (email != null) body['email'] = email;
      if (genres != null) body['genres'] = genres;
      if (instruments != null) body['instruments'] = instruments;
      await _apiService.updateProfile(body);
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}