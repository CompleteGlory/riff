import 'package:json_annotation/json_annotation.dart';
import 'post.dart';
import 'pagination.dart';

part 'posts_response.g.dart';

@JsonSerializable()
class PostsResponse {
  final List<Post> data;
  final Pagination pagination;

  PostsResponse({
    required this.data,
    required this.pagination,
  });

  factory PostsResponse.fromJson(Map<String, dynamic> json) => _$PostsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PostsResponseToJson(this);
}