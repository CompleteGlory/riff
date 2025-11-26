import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/home/add_post/data/models/create_post_request_model.dart';
import 'package:riff/features/home/feed/data/models/post.dart';


class CreatePostRepo {
  final ApiService _apiService;

  CreatePostRepo(this._apiService);

  Future<ApiResult<Post>> createPost(CreatePostRequestModel createPostRequestModel) async {
   try {
      final response = await _apiService.createPost(createPostRequestModel);
      return ApiResult.success(response);
     } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
     }
  }
}