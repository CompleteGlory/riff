import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/home/add_post/data/models/create_post_request_model.dart';
import 'package:riff/features/home/feed/data/models/post.dart';


class UpdatePostRepo {
  final ApiService _apiService;

  UpdatePostRepo(this._apiService);

  Future<ApiResult<Post>> updatePost(
    String postId,
    CreatePostRequestModel updatePostRequestModel,
  ) async {
    try {
      final response = await _apiService.updatePost(postId, updatePostRequestModel);
      
      // Server returns just `true` on success, so we create a minimal Post object
      // with the postId to indicate success
      final successPost = Post(
        id: int.parse(postId),
        content: updatePostRequestModel.content,
        media: updatePostRequestModel.media, author: null, createdAt: '', updatedAt: '', isLiked: null, likesCount: '',
      );
      
      return ApiResult.success(successPost);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}

