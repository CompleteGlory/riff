class ApiConstants {
  static const String apiBASEURL = "https://veto-sandy-enlighten.ngrok-free.dev";
  static const String signUp = "/api/auth/sign-up";
  static const String login = "/api/auth/log-in";
  static const String refreshToken = "/api/auth/refresh";
  static const String requestOtp = "/api/auth/request-otp";
  static const String verifyOtp = "/api/auth/verify-otp";
  static const String resetPassword = "/api/auth/reset-password";
  static const String googleSignin = "/api/auth/google/mobile";
  static const String getUser = "/api/users/me";
  static const String posts = "/api/posts";
  static const String updateDeletePost = "/api/posts/{id}";
  static const String likePost = "/api/posts/{id}/like";
  static const String unlikePost = "/api/posts/{id}/unlike";
  static const String postComments = "/api/posts/{id}/comments";
  static const String comments = "/api/comments/{id}";
  static const String likeComment = "/api/comments/{id}/like";
  static const String unlikeComment = "/api/comments/{id}/unlike";
  static const String userPosts = "/api/users/{id}/posts";
}