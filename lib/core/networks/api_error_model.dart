import 'package:json_annotation/json_annotation.dart';
part 'api_error_model.g.dart';

@JsonSerializable()
class ApiErrorModel {
  final String? message;
  final int? code;
  
  // Change type to List<ApiErrorDetail> to parse individual error objects
  @JsonKey(name: 'errors')
  final List<ApiErrorDetail>? errors;

  ApiErrorModel({
    this.message,
    this.code,
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
    final errorMessage = errors!.map((error) => "${error.msg}").join('\n');
    return errorMessage;
  }
}

// New model to represent individual error details
@JsonSerializable()
class ApiErrorDetail {
  final String? type;
  final String? value;
  final String? msg;
  final String? path;
  final String? location;

  ApiErrorDetail({this.type, this.value, this.msg, this.path, this.location});

  factory ApiErrorDetail.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorDetailToJson(this);
}