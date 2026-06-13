import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/logic/cubit/theme_cubit.dart';
import 'package:riff/core/routing/app_router.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/app_theme.dart';

class RiffApp extends StatelessWidget {
  final AppRouter appRouter;
  final bool startAtHome;

  const RiffApp({
    super.key,
    required this.appRouter,
    this.startAtHome = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>(
      create: (_) => ThemeCubit()..loadTheme(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            builder: (_, __) {
              return MaterialApp(
                title: 'Riff',
                themeMode: themeMode,
                theme: lightTheme(),
                darkTheme: darkTheme(),
                debugShowCheckedModeBanner: false,
                initialRoute: startAtHome ? Routes.home : Routes.onBoarding,
                onGenerateRoute: appRouter.generateRoute,
              );
            },
          );
        },
      ),
    );
  }
}
