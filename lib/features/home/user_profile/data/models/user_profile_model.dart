class UserProfileModel {
  final String id;
  final String fullName;
  final String username;
  final String? bio;
  final String? profileImageUrl;
  final int postsCount;
  final int followersCount;
  final int followingCount;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.bio,
    this.profileImageUrl,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      bio: json['bio'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      postsCount: json['postsCount'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
    );
  }
}
