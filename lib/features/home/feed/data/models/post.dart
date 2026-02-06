import 'package:json_annotation/json_annotation.dart';
import 'author.dart'; // Correct import
import 'comment.dart';
import 'post_like.dart';
// NOTE: Assuming User model is not needed here anymore

part 'post.g.dart';

@JsonSerializable()
class Post {
  final int id;
  
  // FIX 1: Make nullable as it's missing in the response
  @JsonKey(name: 'author_id')
  final String? authorId; 
  
  // FIX 2: Use the simpler Author model
  final Author? author; 
  
  final String? content;
  
  // FIX 3: Make nullable to handle 'media: null'
  final List<String>? media; 
  
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  
  // FIX 4: Make nullable as the array is missing in the response
  final List<PostLike>? likes; 
  
  // FIX 5: Make nullable as the array is missing in the response
  final List<Comment>? comments; 
  
  @JsonKey(name: 'is_liked')
  final bool? isLiked;
  
  // This field matches the JSON (String)
  @JsonKey(name: 'likes_count')
  final String ?likesCount; 

  Post({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.isLiked,
    required this.likesCount,
    
    // Non-required, nullable fields
    this.authorId, 
    this.media,
    this.likes,
    this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}