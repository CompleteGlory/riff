import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/auth/forgot_password/data/models/request_otp_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/reset_password_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/verify_otp_request_body.dart';
import 'package:riff/core/networks/dio_factory.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/helpers/constants.dart';

class ForgotPasswordRepo {
  final ApiService _apiService;
  ForgotPasswordRepo(this._apiService);

  Future<ApiResult<String?>> requestOtp(RequestOtpRequestBody requestOtpRequestBody) async {
    try {
      final response = await _apiService.requestOtp(requestOtpRequestBody);

      // Some APIs return a reset token in the response body (e.g. { "reset_token": "..." }).
      // The generated retrofit signature maps the body to `void`, however the underlying
      // Dio Response is available at `response.response` and may contain the token.
      try {
        final data = response.response.data;
        if (data != null) {
          String? resetToken;
          if (data is Map) {
            resetToken = (data['reset_token'] ?? data['resetToken'])?.toString();
          }

          if (resetToken != null && resetToken.isNotEmpty) {
             print('Debug: Repo - requestOtp found token: "$resetToken"');
            // override the Authorization header with the reset token so subsequent requests
            // (verify OTP / reset password) use it
            DioFactory.setTokenIntoHeaderAfterLogin(resetToken);
            await SharedPrefHelper.setData(SharedPrefKeys.userToken, resetToken);
            return ApiResult.success(resetToken);
          }
        }
      } catch (_) {
        // ignore parsing errors and continue
      }

      return const ApiResult.success(null);
    } catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    }
  }

  Future<ApiResult<String?>> verifyOtp(VerifyOtpRequestBody verifyOtpRequestBody) async {
    try {
      final response = await _apiService.verifyOtp(verifyOtpRequestBody);
      // Extract reset token from verify OTP response body similar to request OTP
      try {
        final data = response.response.data;
        if (data != null) {
          String? resetToken;
          if (data is Map) {
            resetToken = (data['reset_token'] ?? data['resetToken'])?.toString();
          }

          if (resetToken != null && resetToken.isNotEmpty) {
             print('Debug: Repo - verifyOtp found token: "$resetToken"');
            // Store reset token for use in reset password request
            DioFactory.setTokenIntoHeaderAfterLogin(resetToken);
            await SharedPrefHelper.setData(SharedPrefKeys.userToken, resetToken);
            // Return the token so cubit can store it
            return ApiResult.success(resetToken);
          }
        }
      } catch (_) {
        // ignore parsing errors and continue
      }

      return const ApiResult.success(null);
    } catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    }
  }

  Future<ApiResult<void>> resetPassword(ResetPasswordRequestBody resetPasswordRequestBody) async {
     print('Debug: Repo - resetPassword using token: "${resetPasswordRequestBody.resetToken}"');
    try {
      final response = await _apiService.resetPassword(resetPasswordRequestBody);
      return ApiResult.success(response.data);
    } catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    }
  }
}