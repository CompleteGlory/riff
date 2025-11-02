// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:dio/dio.dart';
import 'api_error_model.dart';

class ApiErrorHandler {
  static ApiErrorModel handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionError:
          return ApiErrorModel(message: "Connection to server failed");
        case DioExceptionType.cancel:
          return ApiErrorModel(message: "Request to the server was cancelled");
        case DioExceptionType.connectionTimeout:
          return ApiErrorModel(message: "Connection timeout with the server");
        case DioExceptionType.unknown:
          return ApiErrorModel(
              message:
                  "Connection to the server failed due to internet connection");
        case DioExceptionType.receiveTimeout:
          return ApiErrorModel(
              message: "Receive timeout in connection with the server");
        case DioExceptionType.badResponse:
          return _handleError(error.response?.data, error.response);
        case DioExceptionType.sendTimeout:
          return ApiErrorModel(
              message: "Send timeout in connection with the server");
        case DioExceptionType.badCertificate:
          return ApiErrorModel(message: "Bad certificate");
        }
    } else {
      return ApiErrorModel(message: "Something went wrong");
    }
  }
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
      return ApiErrorModel(
        statusCode: response.statusCode,
        message: data,
      );
    } else {
      return ApiErrorModel(
        statusCode: response.statusCode,
        message: "Unexpected error format",
      );
    }

    // Try to parse as ApiErrorModel
    return ApiErrorModel.fromJson(errorData);
  } catch (e) {
    // Fallback if parsing fails
    return ApiErrorModel(
      statusCode: response.statusCode,
      message: data['message']?.toString() ?? 
               data['error']?.toString() ?? 
               "An error occurred",
    );
  }
}