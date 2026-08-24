// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apple_auth_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppleAuthRequestBody _$AppleAuthRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppleAuthRequestBody(
  identityToken: json['identityToken'] as String,
  fullName: json['fullName'] as String?,
);

Map<String, dynamic> _$AppleAuthRequestBodyToJson(
  AppleAuthRequestBody instance,
) => <String, dynamic>{
  'identityToken': instance.identityToken,
  'fullName': instance.fullName,
};
