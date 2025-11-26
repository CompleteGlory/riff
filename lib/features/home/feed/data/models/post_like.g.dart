// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_like.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostLike _$PostLikeFromJson(Map<String, dynamic> json) => PostLike(
  id: (json['id'] as num).toInt(),
  author: Author.fromJson(json['author'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostLikeToJson(PostLike instance) => <String, dynamic>{
  'id': instance.id,
  'author': instance.author,
};
