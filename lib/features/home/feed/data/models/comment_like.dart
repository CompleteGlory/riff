import 'package:json_annotation/json_annotation.dart';

part 'comment_like.g.dart';

@JsonSerializable()
class CommentLike {
  final String comment;
  @JsonKey(name: 'comment_id')
  final int commentId;
  @JsonKey(name: 'user_id')
  final String userId;
  final dynamic user;

  CommentLike({
    required this.comment,
    required this.commentId,
    required this.userId,
    required this.user,
  });

  factory CommentLike.fromJson(Map<String, dynamic> json) =>
      _$CommentLikeFromJson(json);

  Map<String, dynamic> toJson() => _$CommentLikeToJson(this);
}
