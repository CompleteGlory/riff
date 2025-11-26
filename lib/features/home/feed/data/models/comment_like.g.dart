// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_like.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentLike _$CommentLikeFromJson(Map<String, dynamic> json) => CommentLike(
  comment: json['comment'] as String,
  commentId: (json['comment_id'] as num).toInt(),
  userId: json['user_id'] as String,
  user: json['user'],
);

Map<String, dynamic> _$CommentLikeToJson(CommentLike instance) =>
    <String, dynamic>{
      'comment': instance.comment,
      'comment_id': instance.commentId,
      'user_id': instance.userId,
      'user': instance.user,
    };
