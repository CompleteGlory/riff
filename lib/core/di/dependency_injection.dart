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
import 'package:riff/features/home/feed/logic/cubit/likes/like_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/comments/comment_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/posts/post_cubit.dart';
import 'package:riff/features/home/profile/data/repos/profile_repo.dart';
import 'package:riff/features/home/profile/logic/cubit/profile_cubit.dart';
import 'package:riff/features/home/reels/data/repos/reels_repo.dart';
import 'package:riff/features/home/reels/logic/cubit/reels_cubit.dart';
import 'package:riff/features/home/user_profile/data/repos/user_profile_repo.dart';
import 'package:riff/features/home/user_profile/logic/cubit/user_profile_cubit.dart';
import 'package:riff/features/commercial/data/repos/ad_repo.dart';

final getIt = GetIt.instance;

Future<void> setUpGetIt() async {
  Dio dio = await DioFactory.getDio();

  //Dio & ApiService
  getIt.registerLazySingleton<ApiService>(()=>ApiService(dio));

 //login
  getIt.registerLazySingleton<LoginRepo>(()=>LoginRepo(getIt()));
  getIt.registerFactory<LoginCubit>(()=>LoginCubit(getIt()));

  //signup
  getIt.registerLazySingleton<SignupRepo>(()=>SignupRepo(getIt()));
  getIt.registerFactory<SignupCubit>(()=>SignupCubit(getIt()));

  //forgot password
  getIt.registerLazySingleton<ForgotPasswordRepo>(()=>ForgotPasswordRepo(getIt()));
  getIt.registerFactory<ForgotPasswordCubit>(()=>ForgotPasswordCubit(getIt()));

  //home
  getIt.registerLazySingleton<HomeRepo>(()=>HomeRepo(getIt()));
  getIt.registerFactory<HomeCubit>(()=>HomeCubit(getIt()));

  //feed
  getIt.registerLazySingleton<FeedRepo>(()=>FeedRepo(getIt()));
  getIt.registerFactory<FeedCubit>(()=>FeedCubit(getIt()));
  
  // like operations
  getIt.registerLazySingleton<LikeRepo>(()=>LikeRepo(getIt()));
  getIt.registerFactory<LikeCubit>(()=>LikeCubit(getIt()));
  
  // comment operations
  getIt.registerLazySingleton<CommentRepo>(()=>CommentRepo(getIt()));
  getIt.registerFactory<CommentCubit>(()=>CommentCubit(getIt()));
  
  // post operations
  getIt.registerFactory<PostCubit>(()=>PostCubit(getIt<LikeCubit>(), getIt<FeedCubit>(), getIt<FeedRepo>()));

  // profile
  getIt.registerLazySingleton<ProfileRepo>(() => ProfileRepo(getIt()));
  getIt.registerFactory<ProfileCubit>(() => ProfileCubit(getIt()));

  // user profile (any user)
  getIt.registerLazySingleton<UserProfileRepo>(() => UserProfileRepo(getIt()));
  getIt.registerFactory<UserProfileCubit>(() => UserProfileCubit(getIt()));

  // reels
  getIt.registerLazySingleton<ReelsRepo>(() => ReelsRepo());
  getIt.registerFactory<ReelsCubit>(() => ReelsCubit(getIt()));

  // ads
  getIt.registerLazySingleton<AdRepo>(() => AdRepo(dio));

  //create post
  getIt.registerLazySingleton<CreatePostRepo>(()=>CreatePostRepo(getIt()));
  getIt.registerFactory<CreatePostCubit>(()=>CreatePostCubit(getIt()));

  //update post
  getIt.registerLazySingleton<UpdatePostRepo>(()=>UpdatePostRepo(getIt()));
  getIt.registerFactory<UpdatePostCubit>(()=>UpdatePostCubit(getIt()));

  //delete post
  getIt.registerLazySingleton<DeletePostRepo>(()=>DeletePostRepo(getIt()));
  getIt.registerFactory<DeletePostCubit>(()=>DeletePostCubit(getIt()));
}