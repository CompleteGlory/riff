import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:riff/core/networks/api_services.dart';
import 'package:riff/core/networks/dio_factory.dart';
import 'package:riff/features/auth/forgot_password/data/repos/forgot_pasword_repo.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';
import 'package:riff/features/auth/login/data/repos/login_repo.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'package:riff/features/auth/signup/data/repos/signup_repo.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_cubit.dart';
import 'package:riff/features/home/add_post/data/repos/create_post_repo.dart';
import 'package:riff/features/home/add_post/data/repos/update_post_repo.dart';
import 'package:riff/features/home/add_post/data/repos/delete_post_repo.dart';
import 'package:riff/features/home/add_post/logic/cubit/create_post_cubit.dart';
import 'package:riff/features/home/add_post/logic/cubit/update_post_cubit.dart';
import 'package:riff/features/home/add_post/logic/cubit/delete_post_cubit.dart';
import 'package:riff/features/home/core/data/repos/home_repo.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/feed/data/repos/feed_repo.dart';
import 'package:riff/features/home/feed/data/repos/like_repo.dart';
import 'package:riff/features/home/feed/data/repos/comment_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/comments/comment_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/posts/post_cubit.dart';
import 'package:riff/features/home/follow/data/repos/follow_repo.dart';
import 'package:riff/features/home/follow/logic/cubit/follow_cubit.dart';
import 'package:riff/features/home/notifications/data/repos/notifications_repo.dart';
import 'package:riff/core/networks/socket_service.dart';
import 'package:riff/features/home/notifications/logic/cubit/notifications_cubit.dart';
import 'package:riff/features/home/profile/data/repos/profile_repo.dart';
import 'package:riff/features/home/profile/logic/cubit/profile_cubit.dart';
import 'package:riff/features/home/reels/data/repos/reels_repo.dart';
import 'package:riff/features/home/reels/logic/cubit/reels_cubit.dart';
import 'package:riff/features/home/user_profile/data/repos/user_profile_repo.dart';
import 'package:riff/features/home/user_profile/logic/cubit/user_profile_cubit.dart';
import 'package:riff/features/commercial/data/repos/ad_repo.dart';
import 'package:riff/features/home/search/data/repos/search_repo.dart';
import 'package:riff/features/home/search/logic/search_cubit.dart';
import 'package:riff/features/auth/phone_verify/data/repos/phone_verify_repo.dart';
import 'package:riff/features/auth/phone_verify/logic/cubit/phone_verify_cubit.dart';
import 'package:riff/features/auth/new_user_onboarding/data/repos/suggested_users_repo.dart';
import 'package:riff/features/home/core/data/repos/feedback_repo.dart';
import 'package:riff/features/home/feed/data/repos/report_repo.dart';
import 'package:riff/features/home/chat/data/repos/chat_repo.dart';
import 'package:riff/features/home/chat/data/services/chat_socket_service.dart';
import 'package:riff/features/home/chat/logic/cubit/chats_list_cubit.dart';
import 'package:riff/features/home/chat/logic/cubit/chat_cubit.dart';
import 'package:riff/features/home/block/data/repos/block_repo.dart';
import 'package:riff/features/home/block/logic/cubit/block_cubit.dart';
import 'package:riff/features/social_share/data/repos/link_preview_repo.dart';
import 'package:riff/features/social_share/data/repos/spotify_now_playing_repo.dart';
import 'package:riff/features/home/profile_settings/logic/profile_settings_cubit.dart';
import 'package:riff/features/home/account_settings/logic/change_password_cubit.dart';

final getIt = GetIt.instance;

Future<void> setUpGetIt() async {
  Dio dio = await DioFactory.getDio();

  // Dio & ApiService
  getIt.registerLazySingleton<Dio>(() => dio);
  getIt.registerLazySingleton<ApiService>(() => ApiService(dio));

  // login
  getIt.registerLazySingleton<LoginRepo>(() => LoginRepo(getIt()));
  getIt.registerFactory<LoginCubit>(() => LoginCubit(getIt()));

  // signup
  getIt.registerLazySingleton<SignupRepo>(() => SignupRepo(getIt()));
  getIt.registerFactory<SignupCubit>(() => SignupCubit(getIt(), getIt()));

  // forgot password
  getIt.registerLazySingleton<ForgotPasswordRepo>(() => ForgotPasswordRepo(getIt()));
  getIt.registerFactory<ForgotPasswordCubit>(() => ForgotPasswordCubit(getIt()));

  // home
  getIt.registerLazySingleton<HomeRepo>(() => HomeRepo(getIt()));
  getIt.registerFactory<HomeCubit>(() => HomeCubit(getIt()));

  // feed
  getIt.registerLazySingleton<FeedRepo>(() => FeedRepo(getIt()));
  getIt.registerFactory<FeedCubit>(() => FeedCubit(getIt()));

  // likes (repo only — LikeCubit removed; PostCubit consumes LikeRepo directly)
  getIt.registerLazySingleton<LikeRepo>(() => LikeRepo(getIt()));

  // comments
  getIt.registerLazySingleton<CommentRepo>(() => CommentRepo(getIt()));
  getIt.registerFactory<CommentCubit>(() => CommentCubit(getIt()));

  // post operations — uses LikeRepo (singleton) directly; no FeedCubit dependency
  // so each getIt<PostCubit>() call is independent and doesn't accidentally
  // operate on a stale factory-created FeedCubit instance.
  getIt.registerFactory<PostCubit>(
      () => PostCubit(getIt<LikeRepo>(), getIt<FeedRepo>()));

  // profile (own)
  getIt.registerLazySingleton<ProfileRepo>(() => ProfileRepo(getIt()));
  getIt.registerFactory<ProfileCubit>(() => ProfileCubit(getIt()));

  // user profile (any user)
  getIt.registerLazySingleton<UserProfileRepo>(() => UserProfileRepo(getIt()));
  getIt.registerFactory<UserProfileCubit>(
      () => UserProfileCubit(getIt(), getIt()));

  // reels
  getIt.registerLazySingleton<ReelsRepo>(() => ReelsRepo());
  getIt.registerFactory<ReelsCubit>(() => ReelsCubit(getIt()));

  // ads
  getIt.registerLazySingleton<AdRepo>(() => AdRepo(dio));

  // create post — singleton so the cubit stays alive while a video upload
  // runs in the background and the user navigates away.
  getIt.registerLazySingleton<CreatePostRepo>(() => CreatePostRepo(getIt()));
  getIt.registerLazySingleton<CreatePostCubit>(() => CreatePostCubit(getIt()));

  // update post
  getIt.registerLazySingleton<UpdatePostRepo>(() => UpdatePostRepo(getIt()));
  getIt.registerFactory<UpdatePostCubit>(() => UpdatePostCubit(getIt()));

  // delete post
  getIt.registerLazySingleton<DeletePostRepo>(() => DeletePostRepo(getIt()));
  getIt.registerFactory<DeletePostCubit>(() => DeletePostCubit(getIt()));

  // follow
  getIt.registerLazySingleton<FollowRepo>(() => FollowRepo(dio));
  getIt.registerFactory<FollowCubit>(() => FollowCubit(getIt()));

  // search
  getIt.registerLazySingleton<SearchRepo>(() => SearchRepo(dio));
  getIt.registerFactory<SearchCubit>(() => SearchCubit(getIt()));

  // notifications
  getIt.registerLazySingleton<NotificationsRepo>(() => NotificationsRepo(dio));
  getIt.registerLazySingleton<SocketService>(() => SocketService());
  getIt.registerLazySingleton<NotificationsCubit>(
      () => NotificationsCubit(getIt(), getIt()));

  // phone verification
  getIt.registerLazySingleton<PhoneVerifyRepo>(() => PhoneVerifyRepo(dio));
  getIt.registerFactory<PhoneVerifyCubit>(() => PhoneVerifyCubit(getIt()));

  // onboarding — suggested users
  getIt.registerLazySingleton<SuggestedUsersRepo>(() => SuggestedUsersRepo(dio));

  // feedback (bug reports + feature requests)
  getIt.registerLazySingleton<FeedbackRepo>(() => FeedbackRepo(dio));

  // content reporting (posts + comments)
  getIt.registerLazySingleton<ReportRepo>(() => ReportRepo(dio));

  // chat
  getIt.registerLazySingleton<ChatRepo>(() => ChatRepo(dio));
  getIt.registerLazySingleton<ChatSocketService>(() => ChatSocketService());
  // Singleton so HomeLayout and ChatsListScreen share the same unread state
  getIt.registerLazySingleton<ChatsListCubit>(() => ChatsListCubit(getIt()));
  getIt.registerFactory<ChatCubit>(() => ChatCubit(getIt(), getIt()));

  // block
  getIt.registerLazySingleton<BlockRepo>(() => BlockRepo(dio));
  getIt.registerFactory<BlockCubit>(() => BlockCubit(getIt()));

  // social share — link previews (singleton so cache is shared across the app)
  getIt.registerLazySingleton<LinkPreviewRepo>(() => LinkPreviewRepo(dio));

  // Spotify now-playing (singleton — only one fetch needed per session)
  getIt.registerLazySingleton<SpotifyNowPlayingRepo>(() => SpotifyNowPlayingRepo());

  // profile settings
  getIt.registerFactory<ProfileSettingsCubit>(
      () => ProfileSettingsCubit(getIt()));

  // account settings — change password
  getIt.registerFactory<ChangePasswordCubit>(
      () => ChangePasswordCubit(getIt()));
}
