import 'package:json_annotation/json_annotation.dart';
part 'apple_auth_request_body.g.dart';

@JsonSerializable()
class AppleAuthRequestBody {
  /// The JWT Apple hands the app back as `identityToken`.
  final String identityToken;

  /// Apple returns the user's name on their **first** authorization only, and
  /// never inside the identity token — so if the client doesn't forward it
  /// here, it is lost permanently.
  final String? fullName;

  AppleAuthRequestBody({required this.identityToken, this.fullName});

  factory AppleAuthRequestBody.fromJson(Map<String, dynamic> json) =>
      _$AppleAuthRequestBodyFromJson(json);

  Map<String, dynamic> toJson() => _$AppleAuthRequestBodyToJson(this);
}
