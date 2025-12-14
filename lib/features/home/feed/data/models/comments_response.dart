import 'package:json_annotation/json_annotation.dart';
import 'comment.dart';
import 'pagination.dart';

part 'comments_response.g.dart';

@JsonSerializable()
class CommentsResponse {
  final List<Comment> data;
  final Pagination pagination;

  CommentsResponse({
    required this.data,
    required this.pagination,
  });

  factory CommentsResponse.fromJson(Map<String, dynamic> json) =>
      _$CommentsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CommentsResponseToJson(this);
}
