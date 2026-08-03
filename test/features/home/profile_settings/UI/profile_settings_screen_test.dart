import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/core/data/repos/home_repo.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/profile/UI/profile_screen.dart';
import 'package:riff/features/home/profile_settings/UI/profile_settings_screen.dart';
import 'package:riff/features/home/profile_settings/logic/profile_settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_app.dart';
import 'profile_settings_screen_test.mocks.dart';

/// See profile_settings_screen_test.md for what this covers and why.

@GenerateMocks([HomeRepo])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const profile = UserProfile(
    id: 'me',
    fullName: 'Magd Kamal',
    username: 'magdkamal',
    email: 'magd@example.com',
  );

  late MockHomeRepo repo;
  late HomeCubit homeCubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = MockHomeRepo();
    when(repo.getMe()).thenAnswer((_) async => const ApiResult.success(profile));
    homeCubit = HomeCubit(repo);
  });

  tearDown(() async => homeCubit.close());

  /// Pumps the screen the way `Routes.profileSettings` builds it: the caller's
  /// HomeCubit shared by value, a fresh ProfileSettingsCubit alongside it.
  ///
  /// Pushed on top of a placeholder rather than pumped as `home:` — the screen
  /// pops itself after a successful save, and popping the only route on the
  /// stack is not something a test can assert on.
  Future<void> pumpSettings(
    WidgetTester tester, {
    bool scrollToPreferences = false,
  }) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: homeCubit),
                    BlocProvider(create: (_) => ProfileSettingsCubit(repo)),
                  ],
                  child: ProfileSettingsScreen(
                    profile: profile,
                    scrollToPreferences: scrollToPreferences,
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// The form's own scroll position.
  ///
  /// Not `find.byType(Scrollable).last` — every `TextFormField` contributes its
  /// own horizontal editable scrollable, and those sit *after* the form's in the
  /// tree. Reading one of them gives a permanent offset of 0, which makes a
  /// broken scroll look like a passing test.
  ScrollPosition formScroll(WidgetTester tester) => tester
      .state<ScrollableState>(find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first)
      .position;

  /// How far below the top of the scroll viewport [finder] sits.
  double distanceFromTop(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy -
      tester.getTopLeft(find.byType(SingleChildScrollView)).dy;

  group('opening from the drawer', () {
    testWidgets('starts at the top of the form', (tester) async {
      await pumpSettings(tester);

      expect(formScroll(tester).pixels, 0);
      expect(find.text('Full Name'), findsOneWidget);
    });
  });

  group('opening from the complete-profile nudge', () {
    testWidgets('opens on the genres and instruments pickers', (tester) async {
      await pumpSettings(tester, scrollToPreferences: true);

      // The nudge is about those two fields; the name/username/email block
      // above them is not what the user tapped for.
      expect(formScroll(tester).pixels, greaterThan(0));
      expect(distanceFromTop(tester, find.text('Music Genres')), lessThan(24),
          reason: 'the genres section should be at the top of the viewport');
      expect(find.text('Instruments'), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets('refreshes the shared HomeCubit so the profile tab updates',
        (tester) async {
      when(repo.updateProfile(
        fullName: anyNamed('fullName'),
        username: anyNamed('username'),
        email: anyNamed('email'),
        genres: anyNamed('genres'),
        instruments: anyNamed('instruments'),
      )).thenAnswer((_) async => const ApiResult.success(null));

      await pumpSettings(tester, scrollToPreferences: true);
      clearInteractions(repo);

      await tester.tap(find.text('Guitar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // refreshProfile() re-runs getMe(), which is what rebuilds screens[4] and
      // makes the new instrument show on the profile without a restart. This is
      // why the route must be handed the *caller's* cubit — refreshing a fresh
      // one would save fine and leave the home shell stale.
      verify(repo.getMe()).called(1);
    });
  });
}
