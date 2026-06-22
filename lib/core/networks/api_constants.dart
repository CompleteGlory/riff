import 'package:riff/core/utils/media_url.dart';

class ApiConstants {
  static const String apiBASEURL = "https://riff-production-08f7.up.railway.app";

  /// Resolves a media URL — delegates to [MediaUrl.resolve].
  /// See lib/core/utils/media_url.dart for the single source of truth.
  static String? resolveUrl(String? url) => MediaUrl.resolve(url);
  static const String signUp = "/api/auth/sign-up";
  static const String login = "/api/auth/log-in";
  static const String refreshToken = "/api/auth/refresh";
  static const String requestOtp = "/api/auth/request-otp";
  static const String verifyOtp = "/api/auth/verify-otp";
  static const String resetPassword = "/api/auth/reset-password";
  static const String googleSignin = "/api/auth/google/mobile";
  static const String getUser = "/api/users/me";
  static const String getUserById = "/api/users/{id}";
  static const String posts = "/api/posts";
  static const String updateDeletePost = "/api/posts/{id}";
  static const String likePost = "/api/posts/{id}/like";
  static const String unlikePost = "/api/posts/{id}/unlike";
  static const String postComments = "/api/posts/{id}/comments";
  static const String comments = "/api/comments/{id}";
  static const String likeComment = "/api/comments/{id}/like";
  static const String unlikeComment = "/api/comments/{id}/unlike";
  static const String userPosts = "/api/users/{id}/posts";
  static const String reels = "/api/posts/reels";
  static const String sharePost = "/api/posts/{id}/share";
  static const String recordView = "/api/posts/{id}/view";
  static const String trendingPost = "/api/posts/trending";
  static const String feedAds = "/api/commercial/ads/feed";
  static const String trackAdView = "/api/commercial/ads/{id}/view";

  // Follow
  static String followUser(String id)        => "/api/users/$id/follow";
  static String unfollowUser(String id)      => "/api/users/$id/follow";
  static String acceptFollow(String id)      => "/api/users/$id/follow/accept";
  static String rejectFollow(String id)      => "/api/users/$id/follow/reject";
  static String removeFollower(String id)    => "/api/users/$id/follower";

  // Notifications
  static const String notifications          = "/api/users/me/notifications";
  static const String markNotificationsRead  = "/api/users/me/notifications/read";

  // Privacy
  static const String updatePrivacy          = "/api/users/me/privacy";

  // Profile settings
  static const String updateProfile          = "/api/users/me/profile";
  static const String checkUsername          = "/api/users/me/check-username";
  static const String changePassword         = "/api/users/me/change-password";

  // Followers / Following lists
  static String userFollowers(String id) => "/api/users/$id/followers";
  static String userFollowing(String id) => "/api/users/$id/following";

  // Search & Discover
  static const String searchUsers   = "/api/search/users";
  static const String searchPosts   = "/api/search/posts";
  static const String discoverPosts = "/api/discover/posts";

  // Phone OTP
  static const String sendPhoneOtp   = "/api/auth/phone/send-otp";
  static const String verifyPhoneOtp = "/api/auth/phone/verify-otp";

  // Contacts & suggested
  static const String findContacts   = "/api/users/me/contacts";
  static const String discoverUsers  = "/api/discover/users";

  // Reports (user-submitted)
  static String reportPost(String id)        => "/api/reports/posts/$id";
  static String reportComment(String id)     => "/api/reports/comments/$id";
  static String reportUser(String id)        => "/api/reports/users/$id";
  static const String reportBug              = "/api/reports/bugs";
  static const String reportFeature          = "/api/reports/features";

  // Chat
  static const String chatConversations        = '/api/chat/conversations';
  static const String chatRequests             = '/api/chat/requests';
  static const String chatDirectConversation   = '/api/chat/conversations/direct';
  static const String chatGroupConversation    = '/api/chat/conversations/group';
  static String chatConversation(String id)     => '/api/chat/conversations/$id';
  static String chatMessages(String id)        => '/api/chat/conversations/$id/messages';
  static String chatUpload(String id)          => '/api/chat/conversations/$id/messages/upload';
  static String chatDeleteMessage(String c, String m) => '/api/chat/conversations/$c/messages/$m';
  static String chatAcceptRequest(String id)   => '/api/chat/requests/$id/accept';
  static String chatDeclineRequest(String id)  => '/api/chat/requests/$id';
  static String chatGroupUpdate(String id)     => '/api/chat/conversations/$id/group';
  static const String chatGroupPhotoUpload     = '/api/chat/group/photo';
  static String chatAddParticipant(String id)  => '/api/chat/conversations/$id/participants';
  static String chatRemoveParticipant(String c, String u) => '/api/chat/conversations/$c/participants/$u';

  // Meta / Link preview
  static String linkPreview(String url) => '/api/meta/link-preview?url=${Uri.encodeComponent(url)}';

  // Spotify
  static const String spotifyConnect     = '/api/users/me/spotify/connect';
  static const String spotifyDisconnect  = '/api/users/me/spotify/disconnect';
  static const String spotifyNowPlaying  = '/api/users/me/spotify/now-playing';
  static String spotifyNowPlayingForUser(String id) => '/api/users/$id/spotify/now-playing';

  // Blocks
  static const String blockedUsers             = '/api/blocks';
  static String blockUser(String id)           => '/api/blocks/$id';

  // Admin endpoints
  static const String adminLogin             = "/api/admin/auth/log-in";
  static const String adminReportsPosts      = "/api/admin/reports/posts";
  static const String adminReportsBugs       = "/api/admin/reports/bugs";
  static const String adminReportsFeatures   = "/api/admin/reports/features";
  static String adminDeletePost(String id)   => "/api/admin/posts/$id";
  static String adminNotifyUser(String userId) => "/api/admin/users/$userId/notify";
}