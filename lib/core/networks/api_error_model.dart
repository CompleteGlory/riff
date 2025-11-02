import 'package:json_annotation/json_annotation.dart';

part 'api_error_model.g.dart';

@JsonSerializable()
class ApiErrorModel {
  @JsonKey(name: 'statusCode')
  final int? statusCode;
  final String? message;
  
  @JsonKey(name: 'errors')
  final List<ApiErrorDetail>? errors;

  ApiErrorModel({
    this.statusCode,
    this.message,
    this.errors,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorModelFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorModelToJson(this);

  /// Returns a String containing all the error messages
  String getAllErrorMessages() {
    if (errors == null || errors!.isEmpty) {
      return message ?? "Unknown Error occurred";
    }

    // Iterate over errors list and combine their messages
    final errorMessage = errors!.map((error) => error.message ?? "").join('\n');
    return errorMessage.isNotEmpty ? errorMessage : (message ?? "Unknown Error occurred");
  }
}

@JsonSerializable()
class ApiErrorDetail {
  final String? origin;
  final String? code;
  final String? format;
  final String? pattern;
  
  @JsonKey(name: 'path')
  final List<String>? path;
  
  final String? message;

  ApiErrorDetail({
    this.origin,
    this.code,
    this.format,
    this.pattern,
    this.path,
    this.message,
  });

  factory ApiErrorDetail.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorDetailToJson(this);
  
  /// Get the field name from path array
  String? get fieldName => path?.isNotEmpty == true ? path!.first : null;
}