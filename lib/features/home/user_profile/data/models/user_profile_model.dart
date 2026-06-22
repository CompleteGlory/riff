import 'package:riff/core/networks/api_constants.dart';

class UserProfileModel {
  final String id;
  final String fullName;
  final String username;
  final String? bio;
  final String? profileImageUrl;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isPrivate;
  /// 'not_following' | 'pending' | 'following'
  final String followStatus;
  final bool isFollowingMe;
  final List<String>? genres;
  final List<String>? instruments;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.bio,
    this.profileImageUrl,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    this.isPrivate = false,
    this.followStatus = 'not_following',
    this.isFollowingMe = false,
    this.genres,
    this.instruments,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      bio: json['bio'] as String?,
      profileImageUrl: ApiConstants.resolveUrl(json['profile_image_url'] as String?),
      postsCount: json['postsCount'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      isPrivate: json['is_private'] as bool? ?? false,
      followStatus: json['follow_status'] as String? ?? 'not_following',
      isFollowingMe: json['is_following_me'] as bool? ?? false,
      genres: (json['genres'] as List?)?.cast<String>(),
      instruments: (json['instruments'] as List?)?.cast<String>(),
    );
  }

  UserProfileModel copyWith({
    int? followersCount,
    String? followStatus,
    bool? isFollowingMe,
    List<String>? genres,
    List<String>? instruments,
  }) {
    return UserProfileModel(
      id: id,
      fullName: fullName,
      username: username,
      bio: bio,
      profileImageUrl: profileImageUrl,
      postsCount: postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount,
      isPrivate: isPrivate,
      followStatus: followStatus ?? this.followStatus,
      isFollowingMe: isFollowingMe ?? this.isFollowingMe,
      genres: genres ?? this.genres,
      instruments: instruments ?? this.instruments,
    );
  }
}
