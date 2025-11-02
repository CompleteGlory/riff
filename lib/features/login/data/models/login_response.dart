import 'package:json_annotation/json_annotation.dart';
part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  final String id;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String username;
  final String email;
  final String? password;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  @JsonKey(name: 'reset_token')
  final String? resetToken;
  @JsonKey(name: 'reset_token_expires_at')
  final String? resetTokenExpiresAt;
  @JsonKey(name: 'reset_otp')
  final String? resetOtp;
  @JsonKey(name: 'reset_otp_expires_at')
  final String? resetOtpExpiresAt;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  @JsonKey(name: 'deleted_at')
  final String? deletedAt;

  LoginResponse({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.password,
    this.refreshToken,
    this.resetToken,
    this.resetTokenExpiresAt,
    this.resetOtp,
    this.resetOtpExpiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}