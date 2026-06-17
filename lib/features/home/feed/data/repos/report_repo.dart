import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';

class ReportRepo {
  final Dio _dio;
  ReportRepo(this._dio);

  Future<ApiResult<void>> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) async {
    try {
      await _dio.post(
        '${ApiConstants.apiBASEURL}${ApiConstants.reportPost(postId)}',
        data: {
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        },
      );
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<void>> reportComment({
    required String commentId,
    required String reason,
    String? details,
  }) async {
    try {
      await _dio.post(
        '${ApiConstants.apiBASEURL}${ApiConstants.reportComment(commentId)}',
        data: {
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        },
      );
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}
