import 'dart:io';
import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/core/networks/dio_factory.dart';
import 'package:riff/features/home/add_post/data/models/create_post_request_model.dart';
import 'package:riff/features/home/feed/data/models/post.dart';

class CreatePostRepo {
  final ApiService _apiService;

  CreatePostRepo(this._apiService);

  Future<ApiResult<Post>> createPost(
    CreatePostRequestModel requestModel, {
    List<File>? mediaFiles,
  }) async {
    try {
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        final dio = DioFactory.dio!;
        final parts = await Future.wait(
          mediaFiles.map(
            (f) => MultipartFile.fromFile(
              f.path,
              filename: f.path.split('/').last,
            ),
          ),
        );
        final formData = FormData.fromMap({
          'content': requestModel.content,
          'media': parts,
        });
        final response = await dio.post(
          '${ApiConstants.apiBASEURL}/api/posts',
          data: formData,
        );
        final post = Post.fromJson(response.data as Map<String, dynamic>);
        return ApiResult.success(post);
      } else {
        final response = await _apiService.createPost(requestModel);
        return ApiResult.success(response);
      }
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}
