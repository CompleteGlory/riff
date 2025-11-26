// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_post_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePostRequestModel _$CreatePostRequestModelFromJson(
  Map<String, dynamic> json,
) => CreatePostRequestModel(
  content: json['content'] as String,
  media: (json['media'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$CreatePostRequestModelToJson(
  CreatePostRequestModel instance,
) => <String, dynamic>{'content': instance.content, 'media': instance.media};
