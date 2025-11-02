// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignupResponse _$SignupResponseFromJson(Map<String, dynamic> json) =>
    SignupResponse(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String?,
      refreshToken: json['refresh_token'] as String?,
      resetToken: json['reset_token'] as String?,
      resetTokenExpiresAt: json['reset_token_expires_at'] == null
          ? null
          : DateTime.parse(json['reset_token_expires_at'] as String),
      resetOtp: json['reset_otp'] as String?,
      resetOtpExpiresAt: json['reset_otp_expires_at'] == null
          ? null
          : DateTime.parse(json['reset_otp_expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
    );

Map<String, dynamic> _$SignupResponseToJson(SignupResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'username': instance.username,
      'email': instance.email,
      'password': instance.password,
      'refresh_token': instance.refreshToken,
      'reset_token': instance.resetToken,
      'reset_token_expires_at': instance.resetTokenExpiresAt?.toIso8601String(),
      'reset_otp': instance.resetOtp,
      'reset_otp_expires_at': instance.resetOtpExpiresAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };
