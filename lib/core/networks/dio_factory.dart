import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/routing/navigation_service.dart';

class DioFactory {
  /// private constructor as I don't want to allow creating an instance of this class
  DioFactory._();

  static Dio? dio;

  static Dio getDio() {
    Duration timeOut = const Duration(seconds: 30);

    if (dio == null) {
      dio = Dio();
      dio!
        ..options.connectTimeout = timeOut
        ..options.receiveTimeout = timeOut
        ..options.validateStatus = (status) => status == 200 || status == 201;
      addDioHeaders();
      addDioInterceptor();
      return dio!;
    } else {
      return dio!;
    }
  }

  static void addDioHeaders() async {
    dio?.options.headers = {
      "Authorization":
          "Bearer ${await SharedPrefHelper.getString(SharedPrefKeys.userToken)}"
    };
  }

   static void setTokenIntoHeaderAfterLogin(String token) {
    dio?.options.headers = {
      'Authorization': 'Bearer $token',
    };
  }

  static void addDioInterceptor() {
    // pretty logger first
    dio?.interceptors.add(
      PrettyDioLogger(
        requestBody: true,
        requestHeader: true,
        responseHeader: true,
      ),
    );

    // Interceptor to handle 401 -> try refresh token and retry once
    dio?.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          final statusCode = err.response?.statusCode;
          final requestOptions = err.requestOptions;

          // Only attempt refresh once per request
          if (statusCode == 401 && requestOptions.extra['retried'] != true) {
            try {
              // Use a clean Dio instance to call refresh so we don't trigger the same interceptor
              final refreshDio = Dio();
              final refreshService = ApiService(refreshDio, baseUrl: ApiConstants.apiBASEURL);

              final refreshResp = await refreshService.refreshToken();

              final refreshStatus = refreshResp.response.statusCode;
              if (refreshStatus == 200 || refreshStatus == 201) {
                // Mark retried to avoid infinite loop
                requestOptions.extra['retried'] = true;

                // Retry original request with the (possibly) updated dio instance
                final Response retryResponse = await dio!.fetch(requestOptions);
                return handler.resolve(retryResponse);
              } else if (refreshStatus == 401) {
                // Refresh token is invalid — navigate to login
                NavigationService.navigateToLoginAndClearStack();
                return handler.next(err);
              }
            } catch (e) {
              // If refresh call threw, assume refresh failed and navigate to login
              NavigationService.navigateToLoginAndClearStack();
            }
          }

          return handler.next(err);
        },
      ),
    );
  }
}