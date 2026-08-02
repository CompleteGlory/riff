import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/socket_service.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/features/home/core/data/repos/home_repo.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/notifications/UI/notifications_screen.dart';
import 'package:riff/features/home/notifications/data/models/notification_model.dart';
import 'package:riff/features/home/notifications/data/repos/notifications_repo.dart';
import 'package:riff/features/home/notifications/logic/cubit/notifications_cubit.dart';
import 'package:riff/features/home/profile/UI/profile_screen.dart';
import 'package:riff/features/home/profile_settings/UI/profile_settings_screen.dart'
    show ProfileSettingsArgs;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_app.dart';
import 'notifications_screen_test.mocks.dart';

/// See notifications_screen_test.md for what this covers and why.

class _FakeSocketService extends SocketService {
  @override
  Future<bool> ensureConnected() async => false;
  @override
  void on(String event, Function(dynamic) handler) {}
  @override
  void off(String event) {}
  @override
  void disconnect() {}
}

@GenerateMocks([NotificationsRepo, HomeRepo])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNotificationsRepo repo;
  late NotificationsCubit cubit;

  NotificationModel notification(int id, {bool isRead = false}) =>
      NotificationModel(
        id: id,
        type: 'follow',
        isRead: isRead,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        sender: NotificationSender(
          id: 'u$id',
          username: 'user$id',
          fullName: 'User $id',
        ),
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = MockNotificationsRepo();
    cubit = NotificationsCubit(repo, _FakeSocketService());
  });

  tearDown(() async => cubit.disposePermanently());

  Future<void> pumpScreen(WidgetTester tester) async {
    await pumpApp(
      tester,
      BlocProvider.value(
        value: cubit,
        child: NotificationsScreen(notificationsDenied: () async => false),
      ),
    );
  }

  /// Seeds the cubit with [items].
  ///
  /// silentRefresh(), not load(): load() also starts the 30-second poll, and a
  /// widget test fails with "a timer is still pending" before tearDown gets a
  /// chance to cancel it. silentRefresh() is also exactly what a pull-to-refresh
  /// does, which is what the last test needs.
  Future<void> loadWith(List<NotificationModel> items) async {
    when(repo.getNotifications()).thenAnswer((_) async => NotificationsResponse(
          data: items,
          unreadCount: items.where((n) => !n.isRead).length,
        ));
    await cubit.silentRefresh();
  }

  /// The unread tint the tile paints behind an unread notification. Read
  /// notifications are transparent, and it is the only thing on a follow/like/
  /// comment row that distinguishes the two.
  int unreadRowCount(WidgetTester tester) => tester
      .widgetList<Container>(find.byType(Container))
      .where((c) => c.color != null && c.color != Colors.transparent)
      .length;

  group('mark all as read', () {
    testWidgets('clears the unread styling without a refresh', (tester) async {
      await loadWith([notification(1), notification(2), notification(3)]);
      when(repo.markAllRead()).thenAnswer((_) async {});
      await pumpScreen(tester);

      expect(unreadRowCount(tester), greaterThan(0),
          reason: 'the rows start out unread');

      clearInteractions(repo);

      await tester.tap(find.text('Mark all read'));
      await tester.pump();

      // No pull-to-refresh, no re-fetch — the list must already show every
      // notification as read.
      expect(unreadRowCount(tester), 0);
      verifyNever(repo.getNotifications());
    });

    testWidgets('updates before the server has answered', (tester) async {
      await loadWith([notification(1), notification(2)]);
      final serverCall = Completer<void>();
      when(repo.markAllRead()).thenAnswer((_) => serverCall.future);
      await pumpScreen(tester);

      await tester.tap(find.text('Mark all read'));
      await tester.pump();

      expect(unreadRowCount(tester), 0,
          reason: 'optimistic — the user should not wait on the network');

      serverCall.complete();
      await tester.pumpAndSettle();
      expect(unreadRowCount(tester), 0);
    });

    testWidgets('puts the unread styling back when the server rejects it',
        (tester) async {
      await loadWith([notification(1), notification(2)]);
      when(repo.markAllRead()).thenThrow(Exception('500'));
      await pumpScreen(tester);
      final before = unreadRowCount(tester);

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(unreadRowCount(tester), before);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('a later refresh keeps them read', (tester) async {
      await loadWith([notification(1), notification(2)]);
      when(repo.markAllRead()).thenAnswer((_) async {});
      await pumpScreen(tester);

      await tester.tap(find.text('Mark all read'));
      await tester.pump();

      // The server now reports them read, which is what a refresh returns.
      await loadWith([
        notification(1, isRead: true),
        notification(2, isRead: true),
      ]);
      await tester.pump();

      expect(unreadRowCount(tester), 0);
    });
  });

  group('the complete-profile nudge', () {
    const profile = UserProfile(
      id: 'me',
      fullName: 'Magd Kamal',
      username: 'magdkamal',
      email: 'magd@example.com',
    );

    late MockHomeRepo homeRepo;
    late HomeCubit homeCubit;
    /// What the profileSettings route was handed, if it was reached at all.
    Object? pushedArguments;

    setUp(() {
      pushedArguments = null;
      homeRepo = MockHomeRepo();
      when(homeRepo.getMe())
          .thenAnswer((_) async => const ApiResult.success(profile));
      // The constructor kicks off getMe(); pumpApp's pumpAndSettle lands it.
      homeCubit = HomeCubit(homeRepo);
    });

    tearDown(() async => homeCubit.close());

    /// Pumps the screen with a single complete_profile notification, and a
    /// stand-in for the profileSettings route so the real screen (which wants
    /// its own cubit and the network) never has to build.
    Future<void> pumpNudge(WidgetTester tester) async {
      when(repo.getNotifications()).thenAnswer(
        (_) async => NotificationsResponse(
          data: [
            NotificationModel(
              id: 1,
              type: 'complete_profile',
              isRead: false,
              createdAt: DateTime.now().subtract(const Duration(hours: 15)),
            ),
          ],
          unreadCount: 1,
        ),
      );
      await cubit.silentRefresh();

      await pumpApp(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: homeCubit),
          ],
          child: NotificationsScreen(notificationsDenied: () async => false),
        ),
        routes: {
          Routes.profileSettings: (context) {
            pushedArguments = ModalRoute.of(context)!.settings.arguments;
            return Scaffold(
              body: Column(children: [
                const Text('profile settings'),
                // The nudge is deleted after the push *returns*, so the tests
                // need a way to come back.
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('go back'),
                ),
              ]),
            );
          },
        },
      );
    }

    testWidgets('"Set up" opens profile settings', (tester) async {
      await pumpNudge(tester);

      await tester.tap(find.text('Set up'));
      await tester.pumpAndSettle();

      // It used to push InstrumentsScreen and pop twice on the way back.
      // Genres and instruments are edited on profile settings for every other
      // entry point; the nudge lands in the same place now.
      expect(find.text('profile settings'), findsOneWidget);
    });

    testWidgets('carries the loaded profile and the shared HomeCubit',
        (tester) async {
      await pumpNudge(tester);

      await tester.tap(find.text('Set up'));
      await tester.pumpAndSettle();

      // ProfileSettingsScreen prefills from the profile, and refreshes the
      // HomeCubit it came from after saving — a fresh cubit would leave the
      // home shell showing stale data.
      final args = pushedArguments as ProfileSettingsArgs;
      expect(args.profile, same(profile));
      expect(args.homeCubit, same(homeCubit));
    });

    testWidgets('asks the form to open on the genres and instruments pickers',
        (tester) async {
      await pumpNudge(tester);

      await tester.tap(find.text('Set up'));
      await tester.pumpAndSettle();

      // The nudge is *about* those two fields. Landing at the top of the form
      // leaves the user to go hunting for what they just tapped.
      expect((pushedArguments as ProfileSettingsArgs).scrollToPreferences,
          isTrue);
    });

    testWidgets('tapping the row goes to the same place as the button',
        (tester) async {
      await pumpNudge(tester);

      // Missing the pill shouldn't be a dead end.
      await tester.tap(find.text('Complete your profile to get discovered!'));
      await tester.pumpAndSettle();

      expect(find.text('profile settings'), findsOneWidget);
    });

    testWidgets('the nudge is deleted once the user comes back',
        (tester) async {
      when(repo.deleteNotification(1)).thenAnswer((_) async {});
      await pumpNudge(tester);

      await tester.tap(find.text('Set up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('go back'));
      await tester.pumpAndSettle();

      // Deleted, not marked read: it is a standing reminder, so a read copy
      // left in the list is just clutter. The scheduler puts it back within
      // three days if the profile is still incomplete.
      verify(repo.deleteNotification(1)).called(1);
      expect(find.text('Complete your profile to get discovered!'), findsNothing);
    });

    testWidgets('the nudge survives until the user actually opens settings',
        (tester) async {
      await pumpNudge(tester);

      // Merely rendering the list must not consume it.
      verifyNever(repo.deleteNotification(any));
      expect(
          find.text('Complete your profile to get discovered!'), findsOneWidget);
    });
  });
}
