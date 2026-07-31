import 'package:riff/core/helpers/app_date_time.dart';

class BlockedUser {
  final String id;
  final String username;
  final String fullName;
  final String? profileImageUrl;
  final DateTime blockedAt;

  const BlockedUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.profileImageUrl,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> j) => BlockedUser(
        id: j['id'] as String,
        username: j['username'] as String,
        fullName: j['full_name'] as String,
        profileImageUrl: j['profile_image_url'] as String?,
        blockedAt: parseServerDateTimeOr(j['blocked_at'] as String?),
      );
}
