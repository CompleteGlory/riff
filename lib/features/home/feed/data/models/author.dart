import 'package:json_annotation/json_annotation.dart';

part 'author.g.dart';

@JsonSerializable()
class Author {
  final String id;

  @JsonKey(name: 'full_name')
  final String fullName;

  final String username;

  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;

  Author({
    required this.id,
    required this.fullName,
    required this.username,
    this.profileImageUrl,
  });

  factory Author.fromJson(Map<String, dynamic> json) =>
      _$AuthorFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorToJson(this);
}