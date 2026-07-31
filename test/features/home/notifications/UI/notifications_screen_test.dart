import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/socket_service.dart';
import 'package:riff/features/home/notifications/UI/notifications_screen.dart';
import 'package:riff/features/home/notifications/data/models/notification_model.dart';
import 'package:riff/features/home/notifications/data/repos/notifications_repo.dart';
import 'package:riff/features/home/notifications/logic/cubit/notifications_cubit.dart';
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

@GenerateMocks([NotificationsRepo])
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
}
