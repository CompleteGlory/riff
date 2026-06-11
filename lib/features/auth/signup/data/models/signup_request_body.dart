import 'package:json_annotation/json_annotation.dart';

part 'signup_request_body.g.dart';

@JsonSerializable(explicitToJson: true)
class SignupRequestBody {
  final String email;
  final String password;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String username;
  final List<String> instruments;
  final List<String> genres;

  const SignupRequestBody({
    required this.email,
    required this.password,
    required this.fullName,
    required this.username,
    this.instruments = const [],
    this.genres = const [],
  });

  Map<String, dynamic> toJson() => _$SignupRequestBodyToJson(this);
}