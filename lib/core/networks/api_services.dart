import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/features/login/data/models/login_request_body.dart';
import 'package:riff/features/login/data/models/login_response.dart';
import 'package:riff/features/signup/data/models/signup_request_body.dart';
import 'package:riff/features/signup/data/models/signup_response.dart';
part 'api_services.g.dart';

@RestApi(baseUrl: ApiConstants.apiBASEURL)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST(ApiConstants.login)
  Future<HttpResponse<LoginResponse>> login(@Body() LoginRequestBody loginRequestBody);

  @POST(ApiConstants.signUp)
  Future<SignupResponse> signUp(@Body() SignupRequestBody signUpRequestBody);


}