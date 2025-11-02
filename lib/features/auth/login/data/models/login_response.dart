import 'package:json_annotation/json_annotation.dart';
import 'user.dart';
part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  final User user;

  LoginResponse({
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}