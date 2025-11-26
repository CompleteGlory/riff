import 'package:json_annotation/json_annotation.dart';
part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String? password; // optional, usually not returned by API
  @JsonKey(name: 'full_name')
  final String fullName;
  final String username;
  @JsonKey(name: 'profile_picture')
  final String? profilePicture;
  final String? bio;
  final List<String>? roles;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final bool? isActive;
  final bool? isVerified;

  User({
    required this.id,
    required this.email,
    this.password,
    required this.fullName,
    required this.username,
    this.profilePicture,
    this.bio,
    this.roles,
    this.createdAt,
    this.updatedAt,
    this.isActive,
    this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
