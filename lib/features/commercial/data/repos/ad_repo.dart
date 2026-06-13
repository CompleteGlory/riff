import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/commercial/data/models/ad.dart';

class AdRepo {
  final Dio _dio;

  AdRepo(this._dio);

  Future<ApiResult<List<Ad>>> getFeedAds({int limit = 5}) async {
    try {
      final response = await _dio.get(
        ApiConstants.feedAds,
        queryParameters: {'limit': limit},
      );
      final list = (response.data as List)
          .map((e) => Ad.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(list);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<void> trackView(int adId) async {
    try {
      final path = ApiConstants.trackAdView.replaceFirst('{id}', '$adId');
      await _dio.post(path);
    } catch (_) {
      // fire-and-forget — don't crash on view tracking failure
    }
  }
}
