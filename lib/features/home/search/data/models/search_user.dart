import 'package:riff/core/networks/api_constants.dart';

class SuggestedPost {
  final int id;
  final String content;
  final List<String>? media;
  final DateTime createdAt;
  final int likesCount;

  const SuggestedPost({
    required this.id,
    required this.content,
    this.media,
    required this.createdAt,
    required this.likesCount,
  });

  factory SuggestedPost.fromJson(Map<String, dynamic> json) => SuggestedPost(
        id: json['id'] as int,
        content: json['content'] as String,
        media: (json['media'] as List?)?.map((e) => e as String).toList(),
        createdAt: DateTime.parse(json['created_at'] as String),
        likesCount: json['likes_count'] as int? ?? 0,
      );
}

class SearchUser {
  final String id;
  final String fullName;
  final String username;
  final String? profileImageUrl;
  final bool isPrivate;
  final int? followersCount;
  final List<SuggestedPost> topPosts;

  const SearchUser({
    required this.id,
    required this.fullName,
    required this.username,
    this.profileImageUrl,
    required this.isPrivate,
    this.followersCount,
    this.topPosts = const [],
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) => SearchUser(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        username: json['username'] as String,
        profileImageUrl: ApiConstants.resolveUrl(json['profile_image_url'] as String?),
        isPrivate: json['is_private'] as bool? ?? false,
        followersCount: json['followers_count'] as int?,
        topPosts: (json['top_posts'] as List? ?? [])
            .map((e) => SuggestedPost.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
