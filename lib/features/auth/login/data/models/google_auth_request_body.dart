import 'package:json_annotation/json_annotation.dart';
part 'google_auth_request_body.g.dart';

@JsonSerializable()
class GoogleAuthRequestBody {
  final String idToken;

  GoogleAuthRequestBody({required this.idToken});

  factory GoogleAuthRequestBody.fromJson(Map<String, dynamic> json) =>
      _$GoogleAuthRequestBodyFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleAuthRequestBodyToJson(this);
}
