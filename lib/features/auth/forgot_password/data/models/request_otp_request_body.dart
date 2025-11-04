import 'package:json_annotation/json_annotation.dart';

part 'request_otp_request_body.g.dart';

@JsonSerializable()
class RequestOtpRequestBody {
  final String email;

  RequestOtpRequestBody({
    required this.email,
  });

  Map<String, dynamic> toJson() => _$RequestOtpRequestBodyToJson(this);
}