class ApiConstants {
  static const String apiBASEURL = "http://192.168.1.4:3000";
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
  static const String reportBug              = "/api/reports/bugs";
  static const String reportFeature          = "/api/reports/features";

  // Admin endpoints
  static const String adminLogin             = "/api/admin/auth/log-in";
  static const String adminReportsPosts      = "/api/admin/reports/posts";
  static const String adminReportsBugs       = "/api/admin/reports/bugs";
  static const String adminReportsFeatures   = "/api/admin/reports/features";
  static String adminDeletePost(String id)   => "/api/admin/posts/$id";
  static String adminNotifyUser(String userId) => "/api/admin/users/$userId/notify";
}