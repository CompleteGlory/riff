// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
  id: (json['id'] as num).toInt(),
  author: json['author'] == null
      ? null
      : Author.fromJson(json['author'] as Map<String, dynamic>),
  content: json['content'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
  isLiked: json['is_liked'] as bool?,
  likesCount: json['likes_count'] as String?,
  authorId: json['author_id'] as String?,
  media: (json['media'] as List<dynamic>?)?.map((e) => e as String).toList(),
  likes: (json['likes'] as List<dynamic>?)
      ?.map((e) => PostLike.fromJson(e as Map<String, dynamic>))
      .toList(),
  comments: (json['comments'] as List<dynamic>?)
      ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
      .toList(),
  commentsCount: json['comments_count'] as String? ?? '0',
);

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
  'id': instance.id,
  'author_id': instance.authorId,
  'author': instance.author,
  'content': instance.content,
  'media': instance.media,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'likes': instance.likes,
  'comments': instance.comments,
  'is_liked': instance.isLiked,
  'likes_count': instance.likesCount,
  'comments_count': instance.commentsCount,
};
