import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/logic/cubit/theme_cubit.dart';
import 'package:riff/core/routing/app_router.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/widgets/riff_material_app.dart';
import 'package:riff/features/home/settings/logic/cubit/language_cubit.dart';

class RiffApp extends StatelessWidget {
  const RiffApp({
    super.key,
    required this.appRouter,
    this.startAtHome = false,
    this.needsPrivacyAccept = false,
  });

  final AppRouter appRouter;
  final bool startAtHome;
  final bool needsPrivacyAccept;

  String get _initialRoute {
    if (needsPrivacyAccept) return Routes.privacyPolicyGate;
    return startAtHome ? Routes.home : Routes.onBoarding;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()..loadTheme()),
        BlocProvider<LanguageCubit>(create: (_) => LanguageCubit()..loadLocale()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (_, themeMode) => BlocBuilder<LanguageCubit, Locale>(
          builder: (_, locale) => RiffMaterialApp(
            themeMode: themeMode,
            locale: locale,
            initialRoute: _initialRoute,
            appRouter: appRouter,
            startAtHome: startAtHome,
          ),
        ),
      ),
    );
  }
}
