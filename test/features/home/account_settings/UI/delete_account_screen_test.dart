import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/account_settings/UI/delete_account_screen.dart';
import 'package:riff/features/home/account_settings/data/repos/delete_account_repo.dart';
import 'package:riff/features/home/account_settings/logic/delete_account_cubit.dart';
import 'package:riff/generated/l10n.dart';

import '../../../../helpers/pump_app.dart';
import 'delete_account_screen_test.mocks.dart';

@GenerateMocks([DeleteAccountRepo])
void main() {
  late MockDeleteAccountRepo mockRepo;

  setUp(() {
    mockRepo = MockDeleteAccountRepo();
    when(mockRepo.deleteAccount(
      password: anyNamed('password'),
      confirmUsername: anyNamed('confirmUsername'),
    )).thenAnswer((_) async => const ApiResult.success(null));
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    String username = 'magd',
    String? provider,
  }) {
    return pumpApp(
      tester,
      BlocProvider(
        create: (_) => DeleteAccountCubit(mockRepo),
        child: DeleteAccountScreen(username: username, provider: provider),
      ),
    );
  }

  /// Taps "Delete my account", then the confirm dialog's destructive action.
  Future<void> submitAndConfirm(WidgetTester tester, S s) async {
    await tester.tap(find.text(s.deleteAccountButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.deleteAccountConfirmAction));
    await tester.pumpAndSettle();
  }

  testWidgets('spells out what deletion removes before asking for anything',
      (tester) async {
    await pumpScreen(tester);
    final s = S.of(tester.element(find.byType(DeleteAccountScreen)));

    expect(find.text(s.deleteAccountHeadline), findsOneWidget);
    expect(find.text(s.deleteAccountRemovedProfile), findsOneWidget);
    expect(find.text(s.deleteAccountRemovedContent), findsOneWidget);
    expect(find.text(s.deleteAccountRemovedMessages), findsOneWidget);
    expect(find.text(s.deleteAccountRemovedSocial), findsOneWidget);
  });

  group('password account', () {
    testWidgets('asks for the password', (tester) async {
      await pumpScreen(tester);
      final s = S.of(tester.element(find.byType(DeleteAccountScreen)));

      expect(find.text(s.deleteAccountPasswordLabel), findsOneWidget);
    });

    testWidgets('will not submit an empty password', (tester) async {
      await pumpScreen(tester);
      final s = S.of(tester.element(find.byType(DeleteAccountScreen)));

      await tester.tap(find.text(s.deleteAccountButton));
      await tester.pumpAndSettle();

      expect(find.text(s.deleteAccountPasswordRequired), findsOneWidget);
      // No confirm dialog, and nothing sent.
      expect(find.text(s.deleteAccountConfirmTitle), findsNothing);
      verifyNever(mockRepo.deleteAccount(
        password: anyNamed('password'),
        confirmUsername: anyNamed('confirmUsername'),
      ));
    });

    testWidgets('confirms before deleting, and sends the password',
        (tester) async {
      await pumpScreen(tester);
      final s = S.of(tester.element(find.byType(DeleteAccountScreen)));

      await tester.enterText(find.byType(TextFormField), 'hunter2');
      await tester.tap(find.text(s.deleteAccountButton));
      await tester.pumpAndSettle();

      // The dialog is a deliberate second step — the form alone is too easy to
      // submit by reflex for something irreversible.
      expect(find.text(s.deleteAccountConfirmTitle), findsOneWidget);

      await tester.tap(find.text(s.deleteAccountConfirmAction));
      await tester.pumpAndSettle();

      verify(mockRepo.deleteAccount(
        password: 'hunter2',
        confirmUsername: null,
      )).called(1);
    });

    testWidgets('cancelling the dialog deletes nothing', (tester) async {
      await pumpScreen(tester);
      final s = S.of(tester.element(find.byType(DeleteAccountScreen)));

      await tester.enterText(find.byType(TextFormField), 'hunter2');
      await tester.tap(find.text(s.deleteAccountButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(s.deleteAccountCancel).last);
      await tester.pumpAndSettle();

      verifyNever(mockRepo.deleteAccount(
        password: anyNamed('password'),
        confirmUsername: anyNamed('confirmUsername'),
      ));
    });
  });

  group('OAuth account', () {
    testWidgets('asks for the username instead of a password', (tester) async {
      await pumpScreen(tester, provider: 'google');
      final s = S.of(tester.element(find.byType(DeleteAccountScreen)));

      expect(find.text(s.deleteAccountUsernameLabel('magd')), findsOneWidget);
      expect(find.text(s.deleteAccountPasswordLabel), findsNothing);
    });

    testWidgets('rejects a username that does not match', (tester) async {
      await pumpScreen(tester, provider: 'google');
      final s = S.of(tester.element(find.byType(DeleteAccountScreen)));

      await tester.enterText(find.byType(TextFormField), 'someone-else');
      await tester.tap(find.text(s.deleteAccountButton));
      await tester.pumpAndSettle();

      expect(find.text(s.deleteAccountUsernameMismatch), findsOneWidget);
      verifyNever(mockRepo.deleteAccount(
        password: anyNamed('password'),
        confirmUsername: anyNamed('confirmUsername'),
      ));
    });

    testWidgets('sends the username, not a password', (tester) async {
      await pumpScreen(tester, provider: 'google');
      final s = S.of(tester.element(find.byType(DeleteAccountScreen)));

      await tester.enterText(find.byType(TextFormField), 'magd');
      await submitAndConfirm(tester, s);

      verify(mockRepo.deleteAccount(
        password: null,
        confirmUsername: 'magd',
      )).called(1);
    });
  });
}
