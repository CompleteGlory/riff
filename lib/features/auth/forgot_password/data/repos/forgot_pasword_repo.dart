import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/auth/forgot_password/data/models/request_otp_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/reset_password_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/verify_otp_request_body.dart';

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
            // Returned, never stored. This used to also write the token into
            // SharedPrefKeys.userToken and set it as the global Dio header —
            // and that key is the *live session* credential every
            // authenticated request reads, so a signed-in user who tapped
            // "Forgot password" had their session replaced by a ten-minute
            // reset token. /auth/reset-password is a public endpoint that
            // takes the token in its body, so no header was ever needed.
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
            // Returned to the caller, which passes it to the reset screen as a
            // route argument. See the note in requestOtp for why it is no
            // longer written into the session token key.
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
    try {
      final response = await _apiService.resetPassword(resetPasswordRequestBody);
      return ApiResult.success(response.data);
    } catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    }
  }
}