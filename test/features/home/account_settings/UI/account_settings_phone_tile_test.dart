import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/features/home/account_settings/UI/account_settings_screen.dart';
import 'package:riff/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_app.dart';

/// Covers only the phone-confirmation entry's visibility and its refresh on
/// return. The privacy switch is left alone: toggling it reaches
/// `getIt<FollowCubit>()` directly from the widget rather than through
/// constructor injection, so exercising it here would need the whole DI graph
/// registered (same reasoning as the `new_user_onboarding_screen` exclusion
/// noted in CLAUDE.md).
void main() {
  setUp(() {
    // Widgets on this screen can reach SharedPreferences on the way to their
    // theme/locale state. Without this the platform channel never resolves and
    // the test hangs rather than failing cleanly.
    SharedPreferences.setMockInitialValues({});
  });

  /// Registers a stub at [Routes.confirmPhone] that immediately pops
  /// [confirmResult]. Because it's the only named route registered, a tap that
  /// resolves at all is itself proof the screen pushed that specific route.
  Future<void> pumpSettings(
    WidgetTester tester, {
    required bool phoneVerified,
    Object? confirmResult,
  }) async {
    await pumpApp(
      tester,
      AccountSettingsScreen(initialPhoneVerified: phoneVerified),
      routes: {
        Routes.confirmPhone: (context) => TextButton(
              onPressed: () => Navigator.pop(context, confirmResult),
              child: const Text('stub-confirm-phone'),
            ),
      },
    );
  }

  Future<void> tapEntryAndReturn(WidgetTester tester) async {
    await tester.tap(find.text(S.current.confirmPhoneTile));
    await tester.pumpAndSettle();

    expect(
      find.text('stub-confirm-phone'),
      findsOneWidget,
      reason: 'tapping the entry should push Routes.confirmPhone',
    );

    await tester.tap(find.text('stub-confirm-phone'));
    await tester.pumpAndSettle();
  }

  testWidgets('hides the confirm-phone entry when the number is verified',
      (tester) async {
    await pumpSettings(tester, phoneVerified: true);

    expect(find.text(S.current.confirmPhoneTile), findsNothing);
    // _SectionHeader uppercases its title, so match what's actually rendered.
    expect(find.text(S.current.confirmPhoneSection.toUpperCase()), findsNothing);
    // The rest of the screen is unaffected.
    expect(find.text(S.current.changePasswordTile), findsOneWidget);
  });

  testWidgets('shows the confirm-phone entry when the number is unverified',
      (tester) async {
    await pumpSettings(tester, phoneVerified: false);

    expect(find.text(S.current.confirmPhoneTile), findsOneWidget);
    expect(
      find.text(S.current.confirmPhoneSection.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(S.current.confirmPhoneSub), findsOneWidget);
  });

  testWidgets('defaults to verified, so an unknown state never nags the user',
      (tester) async {
    await pumpApp(tester, const AccountSettingsScreen());

    expect(find.text(S.current.confirmPhoneTile), findsNothing);
  });

  testWidgets('retires the entry once the flow pops true', (tester) async {
    await pumpSettings(tester, phoneVerified: false, confirmResult: true);
    expect(find.text(S.current.confirmPhoneTile), findsOneWidget);

    await tapEntryAndReturn(tester);

    expect(find.text(S.current.confirmPhoneTile), findsNothing);
  });

  testWidgets('keeps the entry when the flow is dismissed without confirming',
      (tester) async {
    // Backing out pops null, not false — the check must read "no result" as
    // "still unverified" rather than as a confirmation.
    await pumpSettings(tester, phoneVerified: false, confirmResult: null);

    await tapEntryAndReturn(tester);

    expect(find.text(S.current.confirmPhoneTile), findsOneWidget);
  });
}
