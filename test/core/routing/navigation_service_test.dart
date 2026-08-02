import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/routing/navigation_service.dart';
import 'package:riff/core/routing/routes.dart';

/// See navigation_service_test.md for what this covers and why.
void main() {
  setUp(() {
    NavigationService.resetForTest();
    NavigationService.readyTimeout = const Duration(milliseconds: 200);
  });

  tearDown(() {
    NavigationService.readyTimeout = const Duration(seconds: 10);
  });

  /// A MaterialApp wired to the real key, with named stand-ins for the routes
  /// these tests care about.
  Widget appUnderTest({String initialRoute = '/start'}) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: initialRoute,
      routes: {
        '/start': (_) => const Scaffold(body: Text('start')),
        '/second': (_) => const Scaffold(body: Text('second')),
        Routes.login: (_) => const Scaffold(body: Text('login')),
      },
    );
  }

  group('navigator readiness', () {
    testWidgets('reports not ready before MaterialApp is built',
        (tester) async {
      expect(NavigationService.isReady, isFalse);
    });

    testWidgets('resolves once the navigator mounts', (tester) async {
      await tester.pumpWidget(appUnderTest());

      expect(NavigationService.isReady, isTrue);
      expect(await NavigationService.waitUntilReady(), isNotNull);
    });

    // The old push-notification code guessed at a fixed 800 ms delay before
    // navigating on a cold start; a slower boot silently dropped the tap.
    //
    // waitUntilReady() polls on real timers, so the waiting has to happen
    // inside runAsync — under the default fake-async clock the poll would never
    // fire and the test would hang instead of failing.
    testWidgets('waits for a navigator that appears late', (tester) async {
      NavigationService.readyTimeout = const Duration(seconds: 5);
      late Future<NavigatorState?> pending;

      await tester.runAsync(() async {
        pending = NavigationService.waitUntilReady();
        // Still nothing mounted a few poll intervals in.
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      expect(NavigationService.isReady, isFalse);

      await tester.pumpWidget(appUnderTest());
      final navigator = await tester.runAsync(() => pending);

      expect(navigator, isNotNull);
    });

    testWidgets('gives up rather than hanging forever', (tester) async {
      // No MaterialApp pumped at all.
      final navigator = await tester.runAsync(
        () => NavigationService.waitUntilReady(
          timeout: const Duration(milliseconds: 150),
        ),
      );

      expect(navigator, isNull);
    });
  });

  group('goToLoginAndClearStack', () {
    testWidgets('lands on login with an empty back stack', (tester) async {
      await tester.pumpWidget(appUnderTest());
      NavigationService.navigator!.pushNamed('/second');
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);

      await NavigationService.goToLoginAndClearStack();
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
      expect(find.text('second'), findsNothing);
      expect(NavigationService.navigator!.canPop(), isFalse,
          reason: 'the user must not be able to go back into the app');
    });

    // Concurrent 401s used to each fire their own redirect, stacking several
    // login screens on top of each other.
    testWidgets('collapses concurrent calls into one navigation',
        (tester) async {
      await tester.pumpWidget(appUnderTest());

      await Future.wait([
        NavigationService.goToLoginAndClearStack(),
        NavigationService.goToLoginAndClearStack(),
        NavigationService.goToLoginAndClearStack(),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('is callable again after the first redirect finishes',
        (tester) async {
      await tester.pumpWidget(appUnderTest());

      await NavigationService.goToLoginAndClearStack();
      await tester.pumpAndSettle();
      NavigationService.navigator!.pushNamed('/second');
      await tester.pumpAndSettle();

      await NavigationService.goToLoginAndClearStack();
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
      expect(NavigationService.isNavigatingToLogin, isFalse);
    });
  });
}
