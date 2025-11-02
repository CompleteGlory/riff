import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/auth/forgot_password/data/models/request_otp_request_body.dart';

class ForgotPasswordRepo {
  final ApiService _apiService;
  ForgotPasswordRepo(this._apiService);

  Future<ApiResult<void>> requestOtp(RequestOtpRequestBody requestOtpRequestBody) async {
    try {
      final response = await _apiService.requestOtp(requestOtpRequestBody);
      return ApiResult.success(response.data);
    } catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    }
  }
}