import 'package:json_annotation/json_annotation.dart';
import 'author.dart';

part 'comment.g.dart';

@JsonSerializable()
class Comment {
  final int? id;
  final String? content;

  /// Maps backend `user` → frontend `Author`
  @JsonKey(name: 'user')
  final Author? author;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'is_liked', defaultValue: false)
  final bool? isLiked;

  Comment({
    required this.id,
    required this.content,
    this.author,
    required this.createdAt,
    this.isLiked = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

  Map<String, dynamic> toJson() => _$CommentToJson(this);
}