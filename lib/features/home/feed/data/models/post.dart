// post.dart

import 'package:json_annotation/json_annotation.dart';
import 'author.dart';
import 'comment.dart';
import 'post_like.dart';

part 'post.g.dart';

@JsonSerializable()
class Post {
  final int id;

  @JsonKey(name: 'author_id')
  final String? authorId;

  final Author? author;
  final String? content;
  final List<String>? media;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  final List<PostLike>? likes;
  final List<Comment>? comments;

  @JsonKey(name: 'is_liked')
  final bool? isLiked;

  @JsonKey(name: 'likes_count')
  final String? likesCount;

  @JsonKey(name: 'comments_count', defaultValue: 0)
  final String? commentsCount;

  @JsonKey(name: 'original_post')
  final Post? originalPost;

  @JsonKey(name: 'shares_count')
  final int? sharesCount;

  Post({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.isLiked,
    required this.likesCount,
    this.authorId,
    this.media,
    this.likes,
    this.comments,
    this.commentsCount,
    this.originalPost,
    this.sharesCount,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}