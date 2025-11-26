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
import 'package:riff/features/home/add_post/logic/cubit/create_post_cubit.dart';
import 'package:riff/features/home/core/data/repos/home_repo.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/feed/data/repos/feed_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/feed_cubit.dart';

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
}