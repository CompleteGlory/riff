import 'package:json_annotation/json_annotation.dart';

part 'reset_password_request_body.g.dart';

@JsonSerializable()
class ResetPasswordRequestBody {
  @JsonKey(name: 'resetToken')
  final String resetToken;

  @JsonKey(name: 'newPassword')
  final String newPassword;

  ResetPasswordRequestBody({
    required this.resetToken,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => _$ResetPasswordRequestBodyToJson(this);

  factory ResetPasswordRequestBody.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestBodyFromJson(json);
}
