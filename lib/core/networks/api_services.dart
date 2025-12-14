import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/features/auth/forgot_password/data/models/request_otp_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/reset_password_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/verify_otp_request_body.dart';
import 'package:riff/features/auth/login/data/models/google_auth_request_body.dart';
import 'package:riff/features/auth/login/data/models/login_request_body.dart';
import 'package:riff/features/auth/signup/data/models/signup_request_body.dart';
import 'package:riff/features/auth/signup/data/models/signup_response.dart';
import 'package:riff/features/home/add_post/data/models/create_post_request_model.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/data/models/comments_response.dart';
import 'package:riff/features/home/feed/data/models/create_comment_request_model.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';
import 'package:riff/features/home/feed/data/models/posts_response.dart';
part 'api_services.g.dart';

@RestApi(baseUrl: ApiConstants.apiBASEURL)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST(ApiConstants.login)
  Future<HttpResponse<dynamic>> login(
    @Body() LoginRequestBody loginRequestBody,
  );

  @POST(ApiConstants.signUp)
  Future<SignupResponse> signUp(@Body() SignupRequestBody signUpRequestBody);

  @POST(ApiConstants.refreshToken)
  Future<HttpResponse<void>> refreshToken();

  @POST(ApiConstants.requestOtp)
  Future<HttpResponse<void>> requestOtp(
    @Body() RequestOtpRequestBody requestOtpRequestBody,
  );

  @POST(ApiConstants.verifyOtp)
  Future<HttpResponse<void>> verifyOtp(
    @Body() VerifyOtpRequestBody verifyOtpRequestBody,
  );

  @PATCH(ApiConstants.resetPassword)
  Future<HttpResponse<void>> resetPassword(
    @Body() ResetPasswordRequestBody resetPasswordRequestBody,
  );

  @POST(ApiConstants.googleSignin)
  Future<HttpResponse<dynamic>> googleLogin(@Body() GoogleAuthRequestBody body);

  @GET(ApiConstants.getUser)
  Future<HttpResponse<dynamic>> getUser();

  @GET(ApiConstants.posts)
  Future<PostsResponse> getPosts(
    @Query("page") int page,
    @Query("limit") int limit,
  );

  @POST(ApiConstants.posts)
  Future<Post> createPost(@Body() CreatePostRequestModel createPostRequestModel);

  @PATCH(ApiConstants.updateDeletePost)
  Future<HttpResponse<dynamic>> updatePost(
    @Path("id") String postId,
    @Body() CreatePostRequestModel updatePostRequestModel,
  );

  @DELETE(ApiConstants.updateDeletePost)
  Future<HttpResponse<void>> deletePost(@Path("id") String postId);

  @POST(ApiConstants.likePost)
  Future<HttpResponse<dynamic>> likePost(@Path("id") String postId);

  @DELETE(ApiConstants.unlikePost)
  Future<HttpResponse<dynamic>> unlikePost(@Path("id") String postId);

  @GET(ApiConstants.postComments)
  Future<HttpResponse<List<Comment>>> getPostComments(
    @Path("id") String postId,
  );

  @POST(ApiConstants.postComments)
  Future<HttpResponse<Comment>> createComment(
    @Path("id") String postId,
    @Body() CreateCommentRequestModel body,
  );
}
