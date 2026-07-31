import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/routing/navigation_service.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/services/notification_route.dart';
import 'package:riff/core/services/push_notification_service.dart';
import 'package:riff/core/services/session_manager.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/features/home/chat/data/repos/chat_repo.dart';
import 'package:riff/features/home/chat/data/services/chat_socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'push_notification_service_test.mocks.dart';

/// See push_notification_service_test.md for what this covers and why.

/// Records the route names pushed onto the root navigator.
class _RouteRecorder extends NavigatorObserver {
  final pushed = <RouteSettings>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route.settings);
  }

  List<String?> get names => pushed.map((s) => s.name).toList();
}

@GenerateMocks([ChatRepo])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RouteRecorder recorder;
  late MockChatRepo chatRepo;
  late ChatSocketService socket;
  late PushNotificationService service;

  final conversation = Conversation(
    id: 'conv-1',
    type: 'direct',
    isRequest: false,
    createdAt: DateTime(2026, 1, 1),
    participants: const [],
  );

  void signIn() => SharedPreferences.setMockInitialValues({
        SharedPrefKeys.userToken: 'access-token',
        SharedPrefKeys.refreshToken: 'refresh-token',
      });

  void signOut() => SharedPreferences.setMockInitialValues({});

  setUp(() {
    signIn();
    SessionManager.resetInstanceForTest();
    NavigationService.resetForTest();
    NavigationService.readyTimeout = const Duration(milliseconds: 200);

    recorder = _RouteRecorder();
    chatRepo = MockChatRepo();
    socket = ChatSocketService();
    getIt
      ..registerSingleton<ChatRepo>(chatRepo)
      ..registerSingleton<ChatSocketService>(socket);

    service = PushNotificationService.instance..reset();
  });

  tearDown(() async {
    NavigationService.readyTimeout = const Duration(seconds: 10);
    service.reset();
    await getIt.reset();
  });

  /// A navigator wired to the real key. Every destination is a stand-in so the
  /// test asserts on *which route was pushed* without booting the real screens
  /// (which want Firebase and the network).
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      navigatorObservers: [recorder],
      initialRoute: Routes.home,
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => Scaffold(body: Text('screen:${settings.name}')),
      ),
    ));
    recorder.pushed.clear(); // ignore the initial route
  }

  group('simple destinations', () {
    testWidgets('a like/comment/follow tap opens the notifications list',
        (tester) async {
      await pumpApp(tester);

      await service.navigateTo(NotificationRoute.notifications);
      await tester.pumpAndSettle();

      expect(recorder.names, [Routes.notifications]);
    });

    testWidgets('a flagged-comment tap opens the comment screen with its ids',
        (tester) async {
      await pumpApp(tester);
      const route = NotificationRoute(
        kind: NotificationRouteKind.flaggedComment,
        commentId: 42,
        postId: 9,
      );

      await service.navigateTo(route);
      await tester.pumpAndSettle();

      expect(recorder.names, [Routes.flaggedComment]);
      expect(recorder.pushed.single.arguments, same(route));
    });

    testWidgets('a flagged-post tap opens the post screen', (tester) async {
      await pumpApp(tester);

      await service.navigateTo(const NotificationRoute(
        kind: NotificationRouteKind.flaggedPost,
        postId: 15,
      ));
      await tester.pumpAndSettle();

      expect(recorder.names, [Routes.flaggedPost]);
    });
  });

  group('chat message taps', () {
    testWidgets('opens the chats list then the conversation on top of it',
        (tester) async {
      await pumpApp(tester);
      when(chatRepo.getConversationById('conv-1'))
          .thenAnswer((_) async => conversation);

      await service.navigateTo(const NotificationRoute(
        kind: NotificationRouteKind.chatConversation,
        conversationId: 'conv-1',
      ));
      await tester.pumpAndSettle();

      // The list underneath is what makes Back land somewhere sensible instead
      // of dumping the user straight out of the app.
      expect(recorder.names, [Routes.chatsList, Routes.chatDetail]);
      expect(recorder.pushed.last.arguments, same(conversation));
    });

    testWidgets('stops at the chats list when the conversation cannot be read',
        (tester) async {
      await pumpApp(tester);
      when(chatRepo.getConversationById('conv-1'))
          .thenThrow(Exception('404 — conversation deleted'));

      await service.navigateTo(const NotificationRoute(
        kind: NotificationRouteKind.chatConversation,
        conversationId: 'conv-1',
      ));
      await tester.pumpAndSettle();

      expect(recorder.names, [Routes.chatsList]);
    });

    testWidgets('does nothing when that conversation is already open',
        (tester) async {
      await pumpApp(tester);
      socket.joinConversation('conv-1'); // user is looking at it right now

      await service.navigateTo(const NotificationRoute(
        kind: NotificationRouteKind.chatConversation,
        conversationId: 'conv-1',
      ));
      await tester.pumpAndSettle();

      expect(recorder.names, isEmpty,
          reason: 'a second message must not stack another copy of the screen');
      verifyNever(chatRepo.getConversationById(any));
    });
  });

  group('taps that arrive before the app can handle them', () {
    // Pushing an authenticated screen on top of the login/onboarding stack is
    // what produced "the notification opened a blank screen".
    testWidgets('a tap while signed out is parked, not pushed', (tester) async {
      signOut();
      await pumpApp(tester);

      await service.navigateTo(NotificationRoute.notifications);
      await tester.pumpAndSettle();

      expect(recorder.names, isEmpty);
    });

    testWidgets('the parked tap is replayed once the user signs in',
        (tester) async {
      signOut();
      await pumpApp(tester);
      await service.navigateTo(NotificationRoute.notifications);
      await tester.pumpAndSettle();
      expect(recorder.names, isEmpty);

      signIn();
      await service.flushPendingRoute();
      await tester.pumpAndSettle();

      expect(recorder.names, [Routes.notifications]);
    });

    testWidgets('replaying twice does not push twice', (tester) async {
      signOut();
      await pumpApp(tester);
      await service.navigateTo(NotificationRoute.notifications);
      signIn();

      await service.flushPendingRoute();
      await service.flushPendingRoute();
      await tester.pumpAndSettle();

      expect(recorder.names, [Routes.notifications]);
    });

    // Replaces the old fixed `Future.delayed(800ms)` guess, which dropped the
    // tap outright when a cold start took longer than that.
    testWidgets('a tap during a cold start waits for the navigator',
        (tester) async {
      NavigationService.readyTimeout = const Duration(seconds: 5);
      late Future<void> navigation;

      await tester.runAsync(() async {
        navigation = service.navigateTo(NotificationRoute.notifications);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      expect(NavigationService.isReady, isFalse);

      await pumpApp(tester);
      await tester.runAsync(() => navigation);
      await tester.pumpAndSettle();

      expect(recorder.names, [Routes.notifications]);
    });
  });

  group('duplicate taps', () {
    // getInitialMessage() and onMessageOpenedApp can both fire for the same
    // tap on some Android launches, which stacked two copies of the screen.
    testWidgets('the same message is only routed once', (tester) async {
      await pumpApp(tester);
      const message = RemoteMessage(
        messageId: 'msg-1',
        data: {'notification_type': 'like'},
      );

      await service.handleMessage(message);
      await service.handleMessage(message);
      await tester.pumpAndSettle();

      expect(recorder.names, [Routes.notifications]);
    });

    testWidgets('a different message still routes', (tester) async {
      await pumpApp(tester);

      await service.handleMessage(const RemoteMessage(
        messageId: 'msg-1',
        data: {'notification_type': 'like'},
      ));
      await service.handleMessage(const RemoteMessage(
        messageId: 'msg-2',
        data: {'notification_type': 'post_flagged', 'post_id': '3'},
      ));
      await tester.pumpAndSettle();

      expect(recorder.names, [Routes.notifications, Routes.flaggedPost]);
    });

    testWidgets('messages without an id are always routed', (tester) async {
      await pumpApp(tester);
      const message = RemoteMessage(data: {'notification_type': 'like'});

      await service.handleMessage(message);
      await service.handleMessage(message);
      await tester.pumpAndSettle();

      expect(recorder.names, [Routes.notifications, Routes.notifications]);
    });
  });
}
