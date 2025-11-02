// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models/login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String?,
      refreshToken: json['refresh_token'] as String?,
      resetToken: json['reset_token'] as String?,
      resetTokenExpiresAt: json['reset_token_expires_at'] as String?,
      resetOtp: json['reset_otp'] as String?,
      resetOtpExpiresAt: json['reset_otp_expires_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      deletedAt: json['deleted_at'] as String?,
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'username': instance.username,
      'email': instance.email,
      'password': instance.password,
      'refresh_token': instance.refreshToken,
      'reset_token': instance.resetToken,
      'reset_token_expires_at': instance.resetTokenExpiresAt,
      'reset_otp': instance.resetOtp,
      'reset_otp_expires_at': instance.resetOtpExpiresAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'deleted_at': instance.deletedAt,
    };
