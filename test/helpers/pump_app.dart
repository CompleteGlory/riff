import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/generated/l10n.dart';

/// Pumps [child] inside a [MaterialApp] configured the same way
/// [RiffMaterialApp] is in production (localization delegates + ScreenUtil),
/// so widgets that use `S.of(context)` or `.w`/`.h`/`.r` work in tests.
///
/// [routes] lets a test stub out destinations the widget under test may
/// navigate to (e.g. Home, signup) without booting the real screens.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Map<String, WidgetBuilder> routes = const {},
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        routes: routes,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
