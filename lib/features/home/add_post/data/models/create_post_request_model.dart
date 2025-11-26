import 'package:json_annotation/json_annotation.dart';

part 'create_post_request_model.g.dart';

@JsonSerializable()
class CreatePostRequestModel {
  final String content;

  // Since media is optional and may be sent as a list of strings
  final List<String>? media;

  CreatePostRequestModel({
    required this.content,
    this.media,
  });

  Map<String, dynamic> toJson() => _$CreatePostRequestModelToJson(this);
}