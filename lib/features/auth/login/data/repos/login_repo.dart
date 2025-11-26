import 'dart:convert';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/features/auth/login/data/models/google_auth_request_body.dart';
import 'package:riff/features/auth/login/data/models/login_request_body.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/login/data/models/user.dart';
import 'package:riff/core/networks/dio_factory.dart';

class LoginRepo {
  final ApiService _apiService;

  LoginRepo(this._apiService);

  /// Email/Password login
  Future<ApiResult<LoginResponse>> login(LoginRequestBody body) async {
    try {
      final response = await _apiService.login(body);
      return _handleLoginResponse(response, body.email);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  /// Google login/signup
  Future<ApiResult<LoginResponse>> loginWithGoogle(String idToken) async {
    try {
      final body = GoogleAuthRequestBody(idToken: idToken);
      final response = await _apiService.googleLogin(body);
      return _handleLoginResponse(response, "");
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  /// Handles login response, stores both Access & Refresh tokens
  Future<ApiResult<LoginResponse>> _handleLoginResponse(
      dynamic response, String fallbackEmail) async {
    try {
      final cookies = response.response.headers.map['set-cookie'];
      String? accessToken;
      String? refreshToken;

      // ✅ Extract tokens from cookies
      if (cookies != null) {
        for (var cookie in cookies) {
          if (cookie.startsWith('AccessToken=')) {
            accessToken = cookie.split(';')[0].replaceFirst('AccessToken=', '');
          } else if (cookie.startsWith('RefreshToken=')) {
            refreshToken = cookie.split(';')[0].replaceFirst('RefreshToken=', '');
          }
        }

        // ✅ Save Access Token
        if (accessToken != null) {
          await SharedPrefHelper.setData(SharedPrefKeys.userToken, accessToken);
          DioFactory.setTokenIntoHeaderAfterLogin(accessToken);
          print('✅ Access token saved: ${accessToken.substring(0, 20)}...');
        } else {
          print('⚠️ No AccessToken found in cookies');
        }

        // ✅ Save Refresh Token
        if (refreshToken != null) {
          await SharedPrefHelper.setData(SharedPrefKeys.refreshToken, refreshToken);
          print('✅ Refresh token saved: ${refreshToken.substring(0, 20)}...');
        } else {
          print('⚠️ No RefreshToken found in cookies');
        }
      } else {
        print('⚠️ No cookies found in response');
      }

      // ✅ Parse user data
      final raw = response.response.data;
      User user;
      if (raw is Map<String, dynamic> && raw['user'] != null) {
        user = User.fromJson(raw['user']);
      } else {
        user = await _fallbackUser(raw, accessToken, fallbackEmail);
      }

      // ✅ Save userId
      await SharedPrefHelper.setData(SharedPrefKeys.userId, user.id);
      print('✅ User ID saved: ${user.id}');

      return ApiResult.success(LoginResponse(user: user));
    } catch (e) {
      print('❌ Error in _handleLoginResponse: $e');
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
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

    return User(id: id, email: email, fullName: '', username: '');
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