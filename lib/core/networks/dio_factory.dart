import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/routing/navigation_service.dart';

class DioFactory {
  DioFactory._();

  static Dio? dio;

  static Future<Dio> getDio() async {
    Duration timeOut = const Duration(seconds: 30);

    if (dio == null) {
      dio = Dio();
      dio!
        ..options.connectTimeout = timeOut
        ..options.receiveTimeout = timeOut
        ..options.validateStatus = (status) => status == 200 || status == 201;
      
      await addDioHeaders();
      addDioInterceptor();
      return dio!;
    } else {
      return dio!;
    }
  }

  static Future<void> addDioHeaders() async {
    final token = await SharedPrefHelper.getString(SharedPrefKeys.userToken);
    dio?.options.headers = {
      "Authorization": "Bearer ${token ?? ''}",
      "Cookie": "AccessToken=${token ?? ''}"  // ✅ Add cookie header
    };
  }

  static void setTokenIntoHeaderAfterLogin(String token) {
    dio?.options.headers = {
      'Authorization': 'Bearer $token',
      'Cookie': 'AccessToken=$token',  // ✅ Add cookie header
    };
  }

  static void addDioInterceptor() {
    dio?.interceptors.add(
      PrettyDioLogger(
        requestBody: true,
        requestHeader: true,
        responseHeader: true,
      ),
    );

    dio?.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          final statusCode = err.response?.statusCode;
          final requestOptions = err.requestOptions;
          final requestPath = requestOptions.uri.toString();

          // Skip interceptor for login endpoint
          if (requestPath.contains(ApiConstants.login)) {
            return handler.next(err);
          }

          // Only attempt refresh once per request
          if (statusCode == 401 && requestOptions.extra['retried'] != true) {
            try {
              print('🔄 Attempting token refresh...');
              
              // Get refresh token from storage
              final refreshToken = await SharedPrefHelper.getString(
                SharedPrefKeys.refreshToken
              );
              
              if (refreshToken == null || refreshToken.isEmpty) {
                print('❌ No refresh token found, navigating to login');
                NavigationService.navigateToLoginAndClearStack();
                return handler.next(err);
              }

              // Create a new Dio instance for refresh call
              final refreshDio = Dio();
              refreshDio.options.baseUrl = ApiConstants.apiBASEURL;
              refreshDio.options.headers = {
                'Cookie': 'RefreshToken=$refreshToken'
              };

              final refreshService = ApiService(
                refreshDio,
                baseUrl: ApiConstants.apiBASEURL
              );

              // Call refresh endpoint
              final refreshResp = await refreshService.refreshToken();
              final refreshStatus = refreshResp.response.statusCode;

              if (refreshStatus == 200 || refreshStatus == 201) {
                print('✅ Token refresh successful');
                
                // Extract new access token from cookies
                final cookies = refreshResp.response.headers.map['set-cookie'];
                String? newAccessToken;
                String? newRefreshToken;

                if (cookies != null) {
                  for (var cookie in cookies) {
                    if (cookie.startsWith('AccessToken=')) {
                      newAccessToken = cookie
                          .split(';')[0]
                          .replaceFirst('AccessToken=', '');
                    } else if (cookie.startsWith('RefreshToken=')) {
                      newRefreshToken = cookie
                          .split(';')[0]
                          .replaceFirst('RefreshToken=', '');
                    }
                  }
                }

                if (newAccessToken != null) {
                  // Save new access token
                  await SharedPrefHelper.setData(
                    SharedPrefKeys.userToken,
                    newAccessToken
                  );
                  
                  // Update Dio headers globally (both Authorization and Cookie)
                  setTokenIntoHeaderAfterLogin(newAccessToken);
                  
                  // ✅ Update BOTH headers in the failed request
                  requestOptions.headers['Authorization'] = 
                      'Bearer $newAccessToken';
                  requestOptions.headers['Cookie'] = 
                      'AccessToken=$newAccessToken';
                  
                  print('✅ New access token set: ${newAccessToken.substring(0, 20)}...');
                } else {
                  print('⚠️ No new access token in refresh response');
                  NavigationService.navigateToLoginAndClearStack();
                  return handler.next(err);
                }

                // Save new refresh token if provided
                if (newRefreshToken != null) {
                  await SharedPrefHelper.setData(
                    SharedPrefKeys.refreshToken,
                    newRefreshToken
                  );
                  print('✅ New refresh token saved');
                }

                // Mark as retried to prevent infinite loop
                requestOptions.extra['retried'] = true;

                // Retry the original request with new token
                print('🔄 Retrying original request...');
                final retryResponse = await dio!.fetch(requestOptions);
                print('✅ Retry successful!');
                return handler.resolve(retryResponse);
                
              } else {
                print('❌ Refresh failed with status: $refreshStatus');
                NavigationService.navigateToLoginAndClearStack();
                return handler.next(err);
              }
            } catch (e) {
              print('❌ Refresh token error: $e');
              NavigationService.navigateToLoginAndClearStack();
              return handler.next(err);
            }
          }

          return handler.next(err);
        },
      ),
    );
  }
}