import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/routing/app_router.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';

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
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Riff App',
          theme: ThemeData(
            useMaterial3: true,
            progressIndicatorTheme: ProgressIndicatorThemeData(
              color: ColorManager.primaryBlack,
            ),
            primaryColor: ColorManager.primaryBlack,
            primarySwatch: ColorManager.primaryBlack, tabBarTheme: TabBarThemeData(indicatorColor: ColorManager.primaryBlack),
          ),
          debugShowCheckedModeBanner: false,
          initialRoute: startAtHome ? Routes.home : Routes.onBoarding,
          onGenerateRoute: appRouter.generateRoute,
        );
      },
    );
  }
}