import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/features/login/data/models/login_request_body.dart';
import 'package:riff/features/login/data/models/login_response.dart';
part 'api_services.g.dart';

@RestApi(baseUrl: ApiConstants.apiBASEURL)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST(ApiConstants.login)
  Future<LoginResponse> login(@Body() LoginRequestBody loginRequestBody);

  // @POST(ApiConstants.signUp)
  // Future<SignUpResponse> signUp(@Body() SignUpRequestBody signUpRequestBody);


}