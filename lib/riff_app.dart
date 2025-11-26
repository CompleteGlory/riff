import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/routing/app_router.dart';
import 'package:riff/core/routing/routes.dart';

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
      designSize: const Size(375, 812), // set your design screen size
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Riff App',
          debugShowCheckedModeBanner: false,
          initialRoute: startAtHome ? Routes.home : Routes.onBoarding,
          onGenerateRoute: appRouter.generateRoute,
        );
      },
    );
  }
}