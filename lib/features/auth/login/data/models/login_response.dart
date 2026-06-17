import 'package:json_annotation/json_annotation.dart';
import 'user.dart';
part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  final User user;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isNewUser;

  LoginResponse({
    required this.user,
    this.isNewUser = false,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}