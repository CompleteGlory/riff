// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_comment_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCommentRequestModel _$CreateCommentRequestModelFromJson(
  Map<String, dynamic> json,
) => CreateCommentRequestModel(
  content: json['content'] as String,
  parentCommentId: (json['parent_comment_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$CreateCommentRequestModelToJson(
  CreateCommentRequestModel instance,
) => <String, dynamic>{
  'content': instance.content,
  'parent_comment_id': instance.parentCommentId,
};
