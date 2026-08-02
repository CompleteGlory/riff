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

  @JsonKey(name: 'created_at', defaultValue: '')
  final String createdAt;

  @JsonKey(name: 'updated_at', defaultValue: '')
  final String updatedAt;

  final List<PostLike>? likes;
  final List<Comment>? comments;

  @JsonKey(name: 'is_liked')
  final bool? isLiked;

  @JsonKey(name: 'likes_count')
  final String? likesCount;

  // No defaultValue: the field is a String? and an int default made
  // json_serializable emit `as String? ?? 0`, which doesn't compile. The
  // checked-in .g.dart had been hand-patched to drop it, so any regeneration
  // broke the build. Call sites already handle null
  // (`int.tryParse(commentsCount ?? '0')`), so nothing changes at runtime.
  @JsonKey(name: 'comments_count')
  final String? commentsCount;

  @JsonKey(name: 'original_post')
  final Post? originalPost;

  /// True when this post is a share whose original has since been deleted.
  ///
  /// The original row is gone, so [originalPost] is null and nothing else on
  /// the wire distinguishes a share from a plain post — the API sets this flag
  /// on every share of a post as it is deleted so the quoted card can say the
  /// post is unavailable instead of silently rendering an empty share.
  @JsonKey(name: 'original_post_deleted')
  final bool? originalPostDeleted;

  @JsonKey(name: 'shares_count')
  final int? sharesCount;

  @JsonKey(name: 'views_count', defaultValue: 0)
  final int? viewsCount;

  @JsonKey(name: 'source_url')
  final String? sourceUrl;

  @JsonKey(name: 'source_platform')
  final String? sourcePlatform;

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
    this.originalPostDeleted,
    this.sharesCount,
    this.viewsCount,
    this.sourceUrl,
    this.sourcePlatform,
  });

  /// [clearOriginalPost] drops the quoted post entirely — passing
  /// `originalPost: null` can't, since null is also "leave it alone".
  Post copyWith({
    Author? author,
    String? content,
    List<String>? media,
    String? createdAt,
    String? updatedAt,
    List<PostLike>? likes,
    List<Comment>? comments,
    bool? isLiked,
    String? likesCount,
    String? commentsCount,
    Post? originalPost,
    bool clearOriginalPost = false,
    bool? originalPostDeleted,
    int? sharesCount,
    int? viewsCount,
  }) {
    return Post(
      id: id,
      authorId: authorId,
      author: author ?? this.author,
      content: content ?? this.content,
      media: media ?? this.media,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      originalPost: clearOriginalPost ? null : (originalPost ?? this.originalPost),
      originalPostDeleted: originalPostDeleted ?? this.originalPostDeleted,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      sourceUrl: sourceUrl,
      sourcePlatform: sourcePlatform,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}