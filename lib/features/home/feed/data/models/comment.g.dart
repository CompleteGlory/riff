// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
  id: (json['id'] as num?)?.toInt(),
  content: json['content'] as String?,
  author: json['user'] == null
      ? null
      : Author.fromJson(json['user'] as Map<String, dynamic>),
  createdAt: json['created_at'] as String,
  isLiked: json['is_liked'] as bool? ?? false,
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  'id': instance.id,
  'content': instance.content,
  'user': instance.author,
  'created_at': instance.createdAt,
  'is_liked': instance.isLiked,
};
