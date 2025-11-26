import 'package:json_annotation/json_annotation.dart';

part 'author.g.dart';

@JsonSerializable()
class Author {
  final String id;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String username;

  Author({
    required this.id,
    required this.fullName,
    required this.username,
  });

  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);
  Map<String, dynamic> toJson() => _$AuthorToJson(this);
}