import 'package:json_annotation/json_annotation.dart';

part 'create_post_request_model.g.dart';

@JsonSerializable()
class CreatePostRequestModel {
  final String content;

  final List<String>? media;

  @JsonKey(name: 'source_url')
  final String? sourceUrl;

  @JsonKey(name: 'source_platform')
  final String? sourcePlatform;

  CreatePostRequestModel({
    required this.content,
    this.media,
    this.sourceUrl,
    this.sourcePlatform,
  });

  Map<String, dynamic> toJson() => _$CreatePostRequestModelToJson(this);
}