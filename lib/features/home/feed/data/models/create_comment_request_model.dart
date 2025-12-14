import 'package:json_annotation/json_annotation.dart';

part 'create_comment_request_model.g.dart';

@JsonSerializable()
class CreateCommentRequestModel {
  final String content;

  @JsonKey(name: 'parent_comment_id')
  final int? parentCommentId;

  CreateCommentRequestModel({required this.content, this.parentCommentId});

  factory CreateCommentRequestModel.fromJson(Map<String, dynamic> json) => _$CreateCommentRequestModelFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCommentRequestModelToJson(this);
}
