// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:dio/dio.dart';
import 'package:riff/core/networks/connectivity_service.dart';
import 'api_error_model.dart';

/// Sentinel `statusCode` for "the request never reached the server".
///
/// Nothing about a socket failure produces an HTTP status, but the UI still
/// needs to tell an offline device apart from a server that answered with an
/// error — one gets cached content and a "you're offline" notice, the other
/// gets a real error page. Marking the model beats re-sniffing the English
/// message for the word "connection" at every call site, which is what the
/// screens used to do and which broke outright in Arabic.
const int kOfflineStatusCode = -1;

extension ApiErrorModelX on ApiErrorModel {
  /// True when this failure was a transport failure rather than a server
  /// response.
  bool get isOffline => statusCode == kOfflineStatusCode;
}

class ApiErrorHandler {
  static ApiErrorModel handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionError:
          return _offline("Connection to server failed");
        case DioExceptionType.cancel:
          return ApiErrorModel(message: "Request to the server was cancelled");
        case DioExceptionType.connectionTimeout:
          return _offline("Connection timeout with the server");
        case DioExceptionType.unknown:
          return ConnectivityService.isNetworkFailure(error)
              ? _offline(
                  "Connection to the server failed due to internet connection")
              : ApiErrorModel(message: "Something went wrong");
        case DioExceptionType.receiveTimeout:
          return _offline("Receive timeout in connection with the server");
        case DioExceptionType.badResponse:
          return _handleError(error.response?.data, error.response);
        case DioExceptionType.sendTimeout:
          return _offline("Send timeout in connection with the server");
        case DioExceptionType.badCertificate:
          return ApiErrorModel(message: "Bad certificate");
      }
    } else if (ConnectivityService.isNetworkFailure(error)) {
      return _offline("Connection to server failed");
    } else {
      return ApiErrorModel(message: "Something went wrong");
    }
  }

  static ApiErrorModel _offline(String message) =>
      ApiErrorModel(statusCode: kOfflineStatusCode, message: message);
}

ApiErrorModel _handleError(dynamic data, Response? response) {
  // Graceful handling of null data
  if (data == null || response == null) {
    return ApiErrorModel(
      statusCode: response?.statusCode,
      message: "Unexpected error occurred",
    );
  }

  try {
    // If data is already a Map, use it directly
    Map<String, dynamic> errorData;
    if (data is Map<String, dynamic>) {
      errorData = data;
    } else if (data is String) {
      // If data is a string, try to parse it as JSON
      return ApiErrorModel(statusCode: response.statusCode, message: data);
    } else {
      return ApiErrorModel(
        statusCode: response.statusCode,
        message: "Unexpected error format",
      );
    }

    // Try to parse as ApiErrorModel.
    //
    // The API usually echoes `statusCode` in the body, but nothing guarantees
    // it — and a caller that branches on the status (the delete-account screen
    // tells "wrong password" from "something went wrong" by the 401) would
    // silently lose it for any handler that returns a bare `{"message": …}`.
    // Fall back to the status the response actually arrived with.
    final parsed = ApiErrorModel.fromJson(errorData);
    if (parsed.statusCode != null) return parsed;
    return ApiErrorModel(
      statusCode: response.statusCode,
      message: parsed.message,
      errors: parsed.errors,
    );
  } catch (e) {
    // Fallback if parsing fails
    return ApiErrorModel(
      statusCode: response.statusCode,
      message:
          data['message']?.toString() ??
          data['error']?.toString() ??
          "An error occurred",
    );
  }
}
