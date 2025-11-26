import 'package:json_annotation/json_annotation.dart';
import 'author.dart'; // ✅ Use Author, not User

part 'comment.g.dart';

@JsonSerializable()
class Comment {
  final int id;
  final String content;
  
  // FIX: Use Author model instead of the comprehensive User model
  final Author author; 
  
  @JsonKey(name: 'created_at')
  final String createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);
}