// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:dio/dio.dart';
import 'api_error_model.dart';

class ApiErrorHandler {
  static ApiErrorModel? handle(dynamic error) {
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
        default:
          return ApiErrorModel(message: "Something went wrong");
      }
    } else {
      return ApiErrorModel(message: "Something went wrong");
    }
  }
}

ApiErrorModel? _handleError(dynamic data, Response? response) {
  // Graceful handling of null data
  if (data == null || response == null) {
    return ApiErrorModel(
      code: response?.statusCode,
      message: "Unexpected error occurred",
    );
  }

  // Extract message and errors list
  final String? message = data['message'] ?? "An error occurred";
  final List<dynamic>? errorsList = data['errors'];

  // Parse errors into List<ApiErrorDetail>
  final List<ApiErrorDetail>? parsedErrors = errorsList?.map((error) {
          return ApiErrorDetail.fromJson(error);
        }).toList();

  return ApiErrorModel(
    code: response.statusCode,
    message: message,
    errors: parsedErrors,
  );
}