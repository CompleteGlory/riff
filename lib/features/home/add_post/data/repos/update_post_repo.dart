import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/core/networks/dio_factory.dart';
import 'package:riff/features/home/feed/data/models/post.dart';

class UpdatePostRepo {
  final ApiService _apiService;

  UpdatePostRepo(this._apiService);

  Future<ApiResult<Post>> updatePost({
    required String postId,
    required String content,
    required List<String> keepMedia,
    List<File>? newFiles,
  }) async {
    try {
      final dio = DioFactory.dio!;

      final Map<String, dynamic> fields = {
        'content': content,
        'keepMedia': jsonEncode(keepMedia),
      };

      if (newFiles != null && newFiles.isNotEmpty) {
        final parts = await Future.wait(
          newFiles.map(
            (f) => MultipartFile.fromFile(
              f.path,
              filename: f.path.split('/').last,
            ),
          ),
        );
        fields['media'] = parts;
      }

      final formData = FormData.fromMap(fields);

      final response = await dio.patch(
        '${ApiConstants.apiBASEURL}/api/posts/$postId',
        data: formData,
      );

      final post = Post.fromJson(response.data as Map<String, dynamic>);
      return ApiResult.success(post);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}
