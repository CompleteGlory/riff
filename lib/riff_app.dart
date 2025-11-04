import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/routing/app_router.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/routing/navigation_service.dart';
import 'package:riff/main_development.dart';


class RiffApp extends StatelessWidget {
  final AppRouter appRouter;
  const RiffApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
         navigatorKey: NavigationService.navigatorKey,
         onGenerateRoute: appRouter.generateRoute,
         initialRoute: isLoggedInUser ? Routes.home : Routes.onBoarding,
            ),
      );
  }
}


