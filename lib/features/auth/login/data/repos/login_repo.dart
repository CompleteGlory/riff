import 'dart:convert';

import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/core/networks/dio_factory.dart';
import 'package:riff/features/auth/login/data/models/login_request_body.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/login/data/models/user.dart';

class LoginRepo {
  final ApiService _apiService;
  LoginRepo(this._apiService);

  Future<ApiResult<LoginResponse>> login(LoginRequestBody loginRequestBody) async {
    try {
      final HttpResponse<dynamic> response =
          await _apiService.login(loginRequestBody);

      final headersMap = response.response.headers.map;
      final cookies = headersMap['set-cookie'];

      String? accessToken;
      if (cookies != null && cookies.isNotEmpty) {
        for (var cookie in cookies) {
          if (cookie.startsWith('AccessToken=')) {
            accessToken =
                cookie.split(';')[0].replaceFirst('AccessToken=', '');
            break;
          }
        }

        if (accessToken != null) {
          DioFactory.setTokenIntoHeaderAfterLogin(accessToken);
          await SharedPrefHelper.setData(
              SharedPrefKeys.userToken, accessToken);
        }
      }

      final status = response.response.statusCode;
      if (status == 200 || status == 201) {
        final raw = response.response.data;

        if (raw is Map<String, dynamic>) {
          return ApiResult.success(LoginResponse.fromJson(raw));
        }

        String extractedId = '';
        String extractedEmail = loginRequestBody.email;

        if (raw is int) {
          extractedId = raw.toString();
        } else if (raw is String && raw.isNotEmpty) {
          extractedId = raw;
        }

        if (extractedId.isEmpty && accessToken != null) {
          final payload = _decodeJwtPayload(accessToken);
          if (payload != null) {
            extractedId =
                (payload['sub'] ?? payload['id'] ?? '').toString();
            extractedEmail =
                (payload['email'] ?? extractedEmail).toString();
          }
        }

        final fallbackUser =
            User(id: extractedId, email: extractedEmail);
        return ApiResult.success(LoginResponse(user: fallbackUser));
      }

      return ApiResult.failure(ApiErrorHandler.handle(
        'Login failed with status $status',
      ));
    } catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    }
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      var payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));

      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
