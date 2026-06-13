import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/dio_factory.dart';
import 'package:riff/features/home/feed/data/models/posts_response.dart';

class ReelsRepo {
  Future<ApiResult<PostsResponse>> getReels(int page, int limit) async {
    try {
      final dio = DioFactory.dio!;
      final response = await dio.get(
        ApiConstants.apiBASEURL + ApiConstants.reels,
        queryParameters: {'page': page, 'limit': limit},
      );
      final postsResponse = PostsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      return ApiResult.success(postsResponse);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}
