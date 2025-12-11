import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_services.dart';


class DeletePostRepo {
  final ApiService _apiService;

  DeletePostRepo(this._apiService);

  Future<ApiResult<void>> deletePost(String postId) async {
    try {
      await _apiService.deletePost(postId);
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}
