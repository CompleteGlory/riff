import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/routing/app_router.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/services/push_notification_service.dart';
import 'package:riff/core/themes/app_theme.dart';
import 'package:riff/core/widgets/upload_overlay.dart';
import 'package:riff/generated/l10n.dart';

/// The [MaterialApp] for Riff, wrapped in [ScreenUtilInit].
///
/// Accepts [themeMode] and [locale] from the parent BlocBuilders so those
/// remain reactive, while keeping all routing and localisation config here.
class RiffMaterialApp extends StatelessWidget {
  const RiffMaterialApp({
    super.key,
    required this.themeMode,
    required this.locale,
    required this.initialRoute,
    required this.appRouter,
    required this.startAtHome,
  });

  final ThemeMode themeMode;
  final Locale locale;
  final String initialRoute;
  final AppRouter appRouter;
  final bool startAtHome;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        title: 'Riff',
        navigatorKey: PushNotificationService.navigatorKey,
        themeMode: themeMode,
        theme: lightTheme(),
        darkTheme: darkTheme(),
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        initialRoute: initialRoute,
        builder: (_, child) => UploadOverlay(child: child!),
        onGenerateRoute: (settings) {
          if (settings.name == Routes.privacyPolicyGate &&
              settings.arguments == null) {
            return appRouter.generateRoute(
              RouteSettings(
                name: Routes.privacyPolicyGate,
                arguments: startAtHome,
              ),
            );
          }
          return appRouter.generateRoute(settings);
        },
      ),
    );
  }
}
