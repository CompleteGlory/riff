import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/features/auth/forgot_password/data/models/request_otp_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/reset_password_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/verify_otp_request_body.dart';
import 'package:riff/features/auth/login/data/models/login_request_body.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/signup/data/models/signup_request_body.dart';
import 'package:riff/features/auth/signup/data/models/signup_response.dart';
part 'api_services.g.dart';

@RestApi(baseUrl: ApiConstants.apiBASEURL)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST(ApiConstants.login)
  Future<HttpResponse<dynamic>> login(@Body() LoginRequestBody loginRequestBody);

  @POST(ApiConstants.signUp)
  Future<SignupResponse> signUp(@Body() SignupRequestBody signUpRequestBody);

  @POST(ApiConstants.refreshToken)
  Future<HttpResponse<void>> refreshToken();

  @POST(ApiConstants.requestOtp)
  Future<HttpResponse<void>> requestOtp(@Body() RequestOtpRequestBody requestOtpRequestBody);

  @POST(ApiConstants.verifyOtp)
  Future<HttpResponse<void>> verifyOtp(@Body() VerifyOtpRequestBody verifyOtpRequestBody);

  @PATCH(ApiConstants.resetPassword)
  Future<HttpResponse<void>> resetPassword(@Body() ResetPasswordRequestBody resetPasswordRequestBody);

}