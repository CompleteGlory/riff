import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/socket_service.dart';
import 'package:riff/features/home/notifications/data/models/notification_model.dart';
import 'package:riff/features/home/notifications/data/repos/notifications_repo.dart';
import 'package:riff/features/home/notifications/logic/cubit/notifications_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notifications_cubit_test.mocks.dart';

/// See notifications_cubit_test.md for what this covers and why.

/// Keeps the cubit off the network. The real service would try to open a
/// websocket during load().
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
        type: 'like',
        isRead: isRead,
        createdAt: DateTime(2026, 1, 1),
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = MockNotificationsRepo();
    cubit = NotificationsCubit(repo, _FakeSocketService());
  });

  tearDown(() async {
    // disposePermanently, not close: an AppScopedCubit ignores close(), and the
    // 30-second poll timer has to be cancelled or the test binding complains
    // about a pending timer.
    await cubit.disposePermanently();
  });

  Future<void> loadWith(List<NotificationModel> items) async {
    when(repo.getNotifications()).thenAnswer((_) async => NotificationsResponse(
          data: items,
          unreadCount: items.where((n) => !n.isRead).length,
        ));
    await cubit.load();
  }

  group('markAllRead', () {
    test('clears the badge and marks every notification read', () async {
      await loadWith([notification(1), notification(2)]);
      when(repo.markAllRead()).thenAnswer((_) async {});

      final ok = await cubit.markAllRead();

      expect(ok, isTrue);
      final state = cubit.state as NotificationsLoaded;
      expect(state.unreadCount, 0);
      expect(state.notifications.every((n) => n.isRead), isTrue);
      verify(repo.markAllRead()).called(1);
    });

    // The list used to update only *after* the request came back, and every
    // error was swallowed — so a failure looked exactly like a success that
    // hadn't happened yet. This is the "sometimes it works, sometimes it
    // doesn't" the user reported.
    test('reports failure and rolls the list back when the server rejects it',
        () async {
      await loadWith([notification(1), notification(2)]);
      when(repo.markAllRead()).thenThrow(Exception('500'));

      final ok = await cubit.markAllRead();

      expect(ok, isFalse);
      final state = cubit.state as NotificationsLoaded;
      expect(state.unreadCount, 2, reason: 'the badge must come back');
      expect(state.notifications.every((n) => !n.isRead), isTrue);
    });

    test('updates the list before the request resolves', () async {
      await loadWith([notification(1)]);
      final serverCall = Completer<void>();
      when(repo.markAllRead()).thenAnswer((_) => serverCall.future);

      final pending = cubit.markAllRead();
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state as NotificationsLoaded).unreadCount, 0,
          reason: 'optimistic — the user sees it clear immediately');
      serverCall.complete();
      expect(await pending, isTrue);
    });

    test('still tells the server even with nothing loaded yet', () async {
      when(repo.markAllRead()).thenAnswer((_) async {});

      expect(await cubit.markAllRead(), isTrue);
      verify(repo.markAllRead()).called(1);
    });
  });

  // The regression behind "mark all as read stopped working": the notifications
  // route provided this GetIt singleton with BlocProvider(create:), so popping
  // that route closed it — permanently, since GetIt kept returning the same
  // dead instance. Every later markAllRead() then hit `if (!isClosed)` and did
  // nothing at all, with no error anywhere.
  group('surviving route disposal', () {
    test('close() from a BlocProvider leaves the cubit usable', () async {
      await loadWith([notification(1)]);
      when(repo.markAllRead()).thenAnswer((_) async {});

      await cubit.close(); // what BlocProvider does on dispose

      expect(cubit.isClosed, isFalse);
      expect(await cubit.markAllRead(), isTrue);
      expect((cubit.state as NotificationsLoaded).unreadCount, 0);
    });

    test('the polling timer survives a route disposal too', () async {
      await loadWith([notification(1)]);

      await cubit.close();
      await loadWith([notification(1), notification(2)]);

      expect((cubit.state as NotificationsLoaded).notifications, hasLength(2));
    });
  });

  group('reset', () {
    test('wipes state so the next user starts clean', () async {
      await loadWith([notification(1)]);

      cubit.reset();

      expect(cubit.state, isA<NotificationsInitial>());
      expect(cubit.isClosed, isFalse,
          reason: 'reset must not permanently kill the singleton');
    });
  });
}
