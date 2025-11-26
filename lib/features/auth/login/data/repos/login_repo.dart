import 'dart:convert';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/core/networks/dio_factory.dart';
import 'package:riff/features/auth/login/data/models/google_auth_request_body.dart';
import 'package:riff/features/auth/login/data/models/login_request_body.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/login/data/models/user.dart';

class LoginRepo {
  final ApiService _apiService;
  LoginRepo(this._apiService);

  // Email login
  Future<ApiResult<LoginResponse>> login(LoginRequestBody body) async {
    try {
      final response = await _apiService.login(body);
      return _handleResponse(response, body.email);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  // Google login/signup (sends idToken to backend)
  Future<ApiResult<LoginResponse>> loginWithGoogle(String idToken) async {
    try {
      final body = GoogleAuthRequestBody(idToken: idToken);
      final response = await _apiService.googleLogin(body);
      
      return _handleResponse(response, "");
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<LoginResponse>> _handleResponse(HttpResponse response, String fallbackEmail) async {
    final cookies = response.response.headers.map['set-cookie'];
    String? accessToken;

    if (cookies != null) {
      for (var cookie in cookies) {
        if (cookie.startsWith('AccessToken=')) {
          accessToken = cookie.split(';')[0].replaceFirst('AccessToken=', '');
          break;
        }
      }
      if (accessToken != null) {
        DioFactory.setTokenIntoHeaderAfterLogin(accessToken);
        await SharedPrefHelper.setData('userToken', accessToken);
      }
    }

    final status = response.response.statusCode;
    if (status != 200 && status != 201) {
      return ApiResult.failure(ApiErrorHandler.handle("Login failed"));
    }

    final raw = response.response.data;
    if (raw is Map<String, dynamic> && raw["user"] != null) {
      return ApiResult.success(LoginResponse.fromJson(raw));
    }

    final user = await _fallbackUser(raw, accessToken, fallbackEmail);
    return ApiResult.success(LoginResponse(user: user));
  }

  Future<User> _fallbackUser(dynamic raw, String? accessToken, String fallbackEmail) async {
    String id = "";
    String email = fallbackEmail;

    if (raw is Map<String, dynamic>) {
      id = raw["id"]?.toString() ?? "";
      email = raw["email"]?.toString() ?? fallbackEmail;
    }

    if (accessToken != null) {
      final payload = _decodeJwtPayload(accessToken);
      if (payload != null) {
        id = payload["sub"]?.toString() ?? id;
        email = payload["email"]?.toString() ?? email;
      }
    }

    return User(id: id, email: email);
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return json.decode(payload);
    } catch (_) {
      return null;
    }
  }
}
