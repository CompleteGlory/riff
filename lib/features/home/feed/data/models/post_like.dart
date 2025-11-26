// post_like.dart (Hypothetical, but required fix)

import 'package:json_annotation/json_annotation.dart';
import 'author.dart'; // ✅ Use Author

part 'post_like.g.dart';

@JsonSerializable()
class PostLike {
  final int id; // Assuming it has an ID

  // FIX: Use Author for the liker's info
  final Author author; 
  
  // You may have other fields here
  
  PostLike({
    required this.id,
    required this.author,
  });

  factory PostLike.fromJson(Map<String, dynamic> json) => _$PostLikeFromJson(json);
  Map<String, dynamic> toJson() => _$PostLikeToJson(this);
}