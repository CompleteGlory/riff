import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/auth/signup/data/models/signup_request_body.dart';

class SignupRepo {
  final ApiService _apiService;
  SignupRepo(this._apiService);

  Future<ApiResult<void>> signUp(SignupRequestBody signupRequestBody) async {
  try {
    await _apiService.signUp(signupRequestBody);
    return const ApiResult.success(null);
  } catch (error) {
    return ApiResult.failure(ApiErrorHandler.handle(error));
  }
}
}