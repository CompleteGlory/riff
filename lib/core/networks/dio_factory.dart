import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/connectivity_service.dart';
import 'package:riff/core/services/session_manager.dart';

class DioFactory {
  DioFactory._();

  static Dio? dio;

  /// Endpoints that must never trigger the refresh-and-retry path: they either
  /// mint the tokens themselves or are the refresh call.
  static const _authEndpoints = <String>[
    ApiConstants.login,
    ApiConstants.signUp,
    ApiConstants.refreshToken,
    ApiConstants.googleSignin,
  ];

  /// Per-request options for a multipart media upload.
  ///
  /// The global `receiveTimeout` of 30s is right for a JSON call and wrong for
  /// an upload. In dio it does not measure the transfer: it wraps the wait for
  /// the *response headers*, which begins once the body has been written and
  /// ends when the server answers — and the server only answers after it has
  /// pushed the file to Cloudinary and had it transcoded. So a video upload
  /// would stream to 100%, the progress bar would fill, and the request would
  /// then be aborted at 30 seconds while the server was still working. That is
  /// exactly the "reaches the end and doesn't upload" report.
  ///
  /// `sendTimeout` is deliberately left unset: it would put a ceiling on how
  /// slow a connection may be, which is not a failure worth inventing.
  static Options get uploadOptions =>
      Options(receiveTimeout: const Duration(minutes: 5));

  static Future<Dio> getDio() async {
    Duration timeOut = const Duration(seconds: 30);

    if (dio == null) {
      dio = Dio();
      dio!
        ..options.baseUrl = ApiConstants.apiBASEURL
        ..options.connectTimeout = timeOut
        ..options.receiveTimeout = timeOut
        // Accept any 2xx status. The original whitelist (200, 201) caused
        // DioExceptionType.badResponse for every endpoint decorated with
        // @HttpCode(HttpStatus.NO_CONTENT) (204) — e.g. decline/accept request,
        // delete message, add/remove participant.
        ..options.validateStatus = (status) => status != null && status >= 200 && status < 300;

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
      "Cookie": "AccessToken=${token ?? ''}"
    };
  }

  static void setTokenIntoHeaderAfterLogin(String token) {
    dio?.options.headers = {
      'Authorization': 'Bearer $token',
      'Cookie': 'AccessToken=$token',
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
        // Every completed response proves the device can reach the server, and
        // every transport-level failure proves it can't. That is a better
        // offline signal than anything the app could poll for, and it costs
        // nothing — so the connectivity banner and the cached-content fallbacks
        // are driven from right here.
        onResponse: (response, handler) {
          ConnectivityService.instance.reportReachable();
          return handler.next(response);
        },
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          ConnectivityService.instance.reportDioError(err);
          final statusCode = err.response?.statusCode;
          final requestOptions = err.requestOptions;
          final requestPath = requestOptions.uri.toString();

          final isAuthEndpoint =
              _authEndpoints.any((path) => requestPath.contains(path));
          final alreadyRetried = requestOptions.extra['retried'] == true;

          if (statusCode != 401 || isAuthEndpoint || alreadyRetried) {
            return handler.next(err);
          }

          // Every concurrent 401 shares one refresh (see SessionManager) —
          // refreshing per-request rotated the refresh token out from under the
          // other in-flight requests and got the user signed out.
          final newAccessToken =
              await SessionManager.instance.refreshAccessToken();

          if (newAccessToken == null) {
            // Either the session genuinely ended (SessionManager has already
            // cleared storage and routed to login) or the refresh failed
            // transiently. Either way this request just failed — surface its
            // own error rather than inventing a new one.
            return handler.next(err);
          }

          setTokenIntoHeaderAfterLogin(newAccessToken);
          requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          requestOptions.headers['Cookie'] = 'AccessToken=$newAccessToken';
          requestOptions.extra['retried'] = true;

          // FormData (multipart uploads) is a single-use stream — the first
          // attempt already consumed it, so it must be re-serialized before
          // the retry.
          if (requestOptions.data is FormData) {
            requestOptions.data = (requestOptions.data as FormData).clone();
          }

          try {
            final retryResponse = await dio!.fetch(requestOptions);
            return handler.resolve(retryResponse);
          } on DioException catch (retryError) {
            // A retry that fails for its own reasons (404, 500, timeout) is a
            // request failure, NOT an auth failure. The old code funnelled this
            // into the logout branch, which is how a single failed upload could
            // sign the user out.
            debugPrint('DioFactory: retry after refresh failed — $retryError');
            return handler.next(retryError);
          } catch (retryError) {
            debugPrint('DioFactory: retry after refresh threw — $retryError');
            return handler.next(err);
          }
        },
      ),
    );
  }
}
