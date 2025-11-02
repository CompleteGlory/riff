import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/signup/data/models/signup_request_body.dart';
import 'package:riff/features/signup/data/models/signup_response.dart';

class SignupRepo {
  final ApiService _apiService;
  SignupRepo(this._apiService);

  Future<ApiResult<SignupResponse>> signUp(SignupRequestBody signupRequestBody) async {
    try {
      final response = await _apiService.signUp(signupRequestBody);
      return ApiResult.success(response);
    } catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error)!);
    }
  }
}