import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/core/networks/dio_factory.dart';
import 'package:riff/features/login/data/models/login_request_body.dart';
import 'package:riff/features/login/data/models/login_response.dart';

class LoginRepo {
  final ApiService _apiService;
  LoginRepo(this._apiService);

  Future<ApiResult<LoginResponse>> login(LoginRequestBody loginRequestBody) async {
    try {
      final response = await _apiService.login(loginRequestBody);
      
      // Get tokens from cookies in response headers
      final cookies = response.headers.map['set-cookie'];
      if (cookies != null && cookies.isNotEmpty) {
        String? accessToken;
        
        for (var cookie in cookies) {
          if (cookie.startsWith('AccessToken=')) {
            accessToken = cookie.split(';')[0].replaceFirst('AccessToken=', '');
            break;
          }
        }
        
        if (accessToken != null) {
          DioFactory.setTokenIntoHeaderAfterLogin(accessToken);
          await SharedPrefHelper.setData(SharedPrefKeys.userToken, accessToken);
        }
      }
      
      // Convert response data to LoginResponse
      if (response.data != null && response.statusCode == 201) {
        final loginResponse = LoginResponse.fromJson(response.data!);
        return ApiResult.success(loginResponse);
      }
      
      return ApiResult.failure(ApiErrorHandler.handle("Login failed")!);
    } catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error)!);
    }
  }
}