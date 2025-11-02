// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiErrorModel _$ApiErrorModelFromJson(Map<String, dynamic> json) =>
    ApiErrorModel(
      statusCode: (json['statusCode'] as num?)?.toInt(),
      message: json['message'] as String?,
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => ApiErrorDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ApiErrorModelToJson(ApiErrorModel instance) =>
    <String, dynamic>{
      'statusCode': instance.statusCode,
      'message': instance.message,
      'errors': instance.errors,
    };

ApiErrorDetail _$ApiErrorDetailFromJson(Map<String, dynamic> json) =>
    ApiErrorDetail(
      origin: json['origin'] as String?,
      code: json['code'] as String?,
      format: json['format'] as String?,
      pattern: json['pattern'] as String?,
      path: (json['path'] as List<dynamic>?)?.map((e) => e as String).toList(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$ApiErrorDetailToJson(ApiErrorDetail instance) =>
    <String, dynamic>{
      'origin': instance.origin,
      'code': instance.code,
      'format': instance.format,
      'pattern': instance.pattern,
      'path': instance.path,
      'message': instance.message,
    };
