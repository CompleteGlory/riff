class FollowUser {
  final String id;
  final String fullName;
  final String username;
  final String? profileImageUrl;
  final bool isPrivate;
  final String followStatus; // 'following' | 'pending' | 'not_following'

  const FollowUser({
    required this.id,
    required this.fullName,
    required this.username,
    this.profileImageUrl,
    required this.isPrivate,
    required this.followStatus,
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) => FollowUser(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        username: json['username'] as String,
        profileImageUrl: json['profile_image_url'] as String?,
        isPrivate: json['is_private'] as bool? ?? false,
        followStatus: json['follow_status'] as String? ?? 'not_following',
      );

  FollowUser copyWith({String? followStatus}) => FollowUser(
        id: id,
        fullName: fullName,
        username: username,
        profileImageUrl: profileImageUrl,
        isPrivate: isPrivate,
        followStatus: followStatus ?? this.followStatus,
      );
}
