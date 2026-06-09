// comment.dart

import 'package:json_annotation/json_annotation.dart';
import 'author.dart';

part 'comment.g.dart';

@JsonSerializable()
class Comment {
  final int? id;
  final String? content;

  @JsonKey(name: 'user')
  final Author? author;

  @JsonKey(name: 'created_at')
  final String createdAt;

  // Backend returns "isLiked" not "is_liked"
  @JsonKey(name: 'isLiked', defaultValue: false)
  final bool? isLiked;

  @JsonKey(name: 'likes_count', defaultValue: 0)
  final int? likesCount;

  Comment({
    required this.id,
    required this.content,
    this.author,
    required this.createdAt,
    this.isLiked = false,
    this.likesCount = 0,
  });

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

  Map<String, dynamic> toJson() => _$CommentToJson(this);
}