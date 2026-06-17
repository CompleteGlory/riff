import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';

class FeedbackRepo {
  final Dio _dio;
  FeedbackRepo(this._dio);

  Future<ApiResult<void>> reportBug({
    required String title,
    required String description,
    String? stepsToReproduce,
    String severity = 'Medium',
  }) async {
    try {
      await _dio.post(
        '${ApiConstants.apiBASEURL}${ApiConstants.reportBug}',
        data: {
          'title': title,
          'description': description,
          if (stepsToReproduce != null && stepsToReproduce.isNotEmpty)
            'stepsToReproduce': stepsToReproduce,
          'severity': severity,
        },
      );
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<void>> requestFeature({
    required String title,
    required String description,
    String? motivation,
  }) async {
    try {
      await _dio.post(
        '${ApiConstants.apiBASEURL}${ApiConstants.reportFeature}',
        data: {
          'title': title,
          'description': description,
          if (motivation != null && motivation.isNotEmpty)
            'motivation': motivation,
        },
      );
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}
