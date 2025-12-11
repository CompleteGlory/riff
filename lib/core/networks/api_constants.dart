class ApiConstants {
  static const String apiBASEURL = "http://192.168.1.3:3000/api/";
  static const String signUp = "auth/sign-up";
  static const String login = "auth/log-in";
  static const String refreshToken = "auth/refresh";
  static const String requestOtp = "auth/request-otp";
  static const String verifyOtp = "auth/verify-otp";
  static const String resetPassword = "auth/reset-password";
  static const String googleSignin = "auth/google/mobile";
  static const String getUser = "users/me";
  static const String posts = "posts";
  static const String updateDeletePost = "posts/{id}";
  static const String likePost = "posts/{id}/like";
}