import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/logic/cubit/theme_cubit.dart';
import 'package:riff/core/routing/app_router.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/services/push_notification_service.dart';
import 'package:riff/core/themes/app_theme.dart';
import 'package:riff/features/home/settings/logic/cubit/language_cubit.dart';
import 'package:riff/generated/l10n.dart';

class RiffApp extends StatelessWidget {
  final AppRouter appRouter;
  final bool startAtHome;

  const RiffApp({super.key, required this.appRouter, this.startAtHome = false});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()..loadTheme()),
        BlocProvider<LanguageCubit>(
          create: (_) => LanguageCubit()..loadLocale(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              return ScreenUtilInit(
                designSize: const Size(375, 812),
                minTextAdapt: true,
                builder: (_, __) {
                  return MaterialApp(
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
                    initialRoute: startAtHome ? Routes.home : Routes.onBoarding,
                    onGenerateRoute: appRouter.generateRoute,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
