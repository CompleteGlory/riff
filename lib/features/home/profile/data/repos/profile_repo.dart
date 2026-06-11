import 'dart:io';
import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/core/networks/dio_factory.dart';
import 'package:riff/features/home/feed/data/models/post.dart';

class ProfileRepo {
  final ApiService _apiService;

  ProfileRepo(this._apiService);

  Future<ApiResult<List<Post>>> getUserPosts(String userId) async {
    try {
      final response = await _apiService.getUserPosts(userId, 1, 50);
      return ApiResult.success(response.data);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<String>> uploadProfileImage(File file) async {
    try {
      final dio = DioFactory.dio!;
      final formData = FormData.fromMap({
        'profileImage': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
      final response = await dio.post(
        '${ApiConstants.apiBASEURL}/api/users/profile-image',
        data: formData,
      );
      final url = (response.data as Map<String, dynamic>)['profile_image_url'] as String;
      return ApiResult.success(url);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}
