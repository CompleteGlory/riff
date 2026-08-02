import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/routing/navigation_service.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/services/notification_route.dart';
import 'package:riff/core/services/session_manager.dart';
import 'package:riff/features/home/chat/data/repos/chat_repo.dart';
import 'package:riff/features/home/chat/data/services/chat_socket_service.dart';

/// Handles FCM token registration and push notification display / routing.
///
/// Tap routing (foreground banner, background tap, terminated tap) is resolved
/// by [NotificationRoute.fromData]; this class only performs the navigation.
///
/// Everything navigates through [NavigationService.navigatorKey] — the one key
/// `MaterialApp` is actually built with. This class used to own a *second*
/// `GlobalKey<NavigatorState>`, and because that was the one wired into
/// `MaterialApp`, every `NavigationService` call elsewhere in the app resolved
/// to `null` and did nothing.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  /// HomeLayout subscribes to this and calls silentRefresh() so the badge and
  /// list update the moment a foreground FCM message arrives — no restart needed.
  static final _refreshController = StreamController<void>.broadcast();
  static Stream<void> get refreshStream => _refreshController.stream;

  // Lazy: touching FirebaseMessaging.instance before Firebase.initializeApp
  // throws, and the routing half of this class needs to be constructible (and
  // testable) without booting Firebase.
  late final _fcm = FirebaseMessaging.instance;
  late final _localNotifs = FlutterLocalNotificationsPlugin();

  static const _channelId = 'riff_default';
  static const _channelName = 'Riff Notifications';

  /// Small icon for every notification this app raises itself.
  ///
  /// Must be the white-on-transparent silhouette, *not* `@mipmap/ic_launcher`.
  /// Android renders a small icon by taking only its alpha channel and painting
  /// it white; the launcher icon is a fully opaque square (and, on API 26+, an
  /// adaptive icon with a solid colour background), so it came out as a plain
  /// white blob. Notifications the OS draws from an FCM payload already use
  /// this drawable via `default_notification_icon` in AndroidManifest.xml —
  /// which is why only the foreground banners looked wrong.
  static const _androidIcon = '@drawable/ic_notification';

  /// Backdrop for the small icon on Android 12+, which draws it inside a
  /// tinted circle. Mirrors `@color/notification_color` (values/colors.xml),
  /// the value the OS-drawn notifications already pick up from the manifest —
  /// without it Android derives a colour from the launcher icon and the
  /// foreground banner ends up a different colour to the background one.
  static const _androidColor = Color(0xFF111111);

  bool _initialized = false;

  /// Foreground messages awaiting a banner tap, keyed by the local-notification
  /// id. A single "last message" field (what this used to be) routed the second
  /// of two stacked banners to the wrong destination.
  final Map<int, RemoteMessage> _foregroundMessages = {};

  /// Message ids already routed. The same tap can surface through more than one
  /// channel (`getInitialMessage` and `onMessageOpenedApp` both fire on some
  /// Android launches), which produced two stacked copies of the destination.
  final Set<String> _handledMessageIds = {};

  /// A tap that arrived before the user was signed in — replayed by
  /// [flushPendingRoute] once they are.
  NotificationRoute? _pendingRoute;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _requestPermission();
    await _registerToken();

    // The listeners below are process-wide; init() is called again after every
    // login (to register the new user's token) and must not stack duplicates.
    //
    // A route parked while signed out is *not* replayed here: login pushes Home
    // with `pushNamedAndRemoveUntil` right after calling init(), which would
    // wipe it straight back off the stack. HomeLayout flushes it instead, once
    // it is actually on screen.
    if (_initialized) return;
    _initialized = true;

    await _setupLocalNotifications();
    _listenForeground();
    _listenTokenRefresh();
    _listenBackgroundTap();
    unawaited(_checkTerminatedTap());
  }

  // ── Permission ────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  // ── Local notifications (foreground display) ──────────────────────────────

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings(_androidIcon);
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifs.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        // User tapped the foreground local banner — route using the message
        // that banner was built from, not merely the most recent one.
        final message = _foregroundMessages.remove(response.id);
        if (message != null) {
          unawaited(handleMessage(message));
        } else {
          unawaited(navigateTo(NotificationRoute.notifications));
        }
      },
    );

    if (Platform.isAndroid) {
      await _localNotifs
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.high,
          ));
    }
  }

  // ── FCM token ─────────────────────────────────────────────────────────────

  Future<void> _registerToken() async {
    try {
      if (Platform.isIOS) await _fcm.getAPNSToken();
      final token = await _fcm.getToken();
      if (token != null) await _sendTokenToBackend(token);
    } catch (e) {
      debugPrint('PushNotificationService: token error — $e');
    }
  }

  void _listenTokenRefresh() {
    _fcm.onTokenRefresh.listen((token) async {
      await _sendTokenToBackend(token);
    });
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      // validAccessToken() refreshes an expired one first, so registering the
      // FCM token right after a cold start no longer silently 401s.
      final userToken = await SessionManager.instance.validAccessToken();
      if (userToken == null || userToken.isEmpty) {
        debugPrint('PushNotificationService: no auth token, skipping FCM register');
        return;
      }
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.apiBASEURL,
        headers: {
          'Cookie': 'AccessToken=$userToken',
          'Authorization': 'Bearer $userToken',
        },
      ));
      await dio.post('/api/users/me/fcm-token', data: {'token': token});
      debugPrint('PushNotificationService: FCM token registered ✓');
    } catch (e) {
      debugPrint('PushNotificationService: failed to send token — $e');
    }
  }

  // ── Foreground messages ───────────────────────────────────────────────────

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        final id = notification.hashCode;
        _foregroundMessages[id] = message;
        _localNotifs.show(
          id,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              importance: Importance.high,
              priority: Priority.high,
              icon: _androidIcon,
              color: _androidColor,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }

      // Tell HomeLayout to refresh the in-app notification list immediately.
      _refreshController.add(null);
    });
  }

  // ── Background tap ────────────────────────────────────────────────────────

  void _listenBackgroundTap() {
    FirebaseMessaging.onMessageOpenedApp
        .listen((message) => unawaited(handleMessage(message)));
  }

  // ── Terminated tap ────────────────────────────────────────────────────────

  Future<void> _checkTerminatedTap() async {
    final message = await _fcm.getInitialMessage();
    if (message == null) return;
    // handleMessage() waits for the navigator itself — the old fixed 800 ms
    // delay was a guess that dropped the tap on a slow cold start.
    await handleMessage(message);
  }

  // ── Routing ───────────────────────────────────────────────────────────────

  /// Resolves [message] to a destination and navigates there.
  @visibleForTesting
  Future<void> handleMessage(RemoteMessage message) async {
    final messageId = message.messageId;
    if (messageId != null && !_handledMessageIds.add(messageId)) {
      debugPrint('PushNotificationService: ignoring duplicate tap $messageId');
      return;
    }
    // Keep the set from growing unbounded across a long session.
    if (_handledMessageIds.length > 50) {
      _handledMessageIds.remove(_handledMessageIds.first);
    }

    await navigateTo(NotificationRoute.fromData(
      message.data,
      notificationTitle: message.notification?.title,
      notificationBody: message.notification?.body,
    ));
  }

  /// Navigates to [route], waiting for the app to be ready first.
  ///
  /// A tap on a signed-out app is parked in [_pendingRoute] instead of pushing
  /// authenticated screens on top of the onboarding/login stack — which is what
  /// produced the "notification opened a blank chat" reports.
  @visibleForTesting
  Future<void> navigateTo(NotificationRoute route) async {
    final nav = await NavigationService.waitUntilReady();
    if (nav == null) {
      _pendingRoute = route;
      return;
    }

    if (!await SessionManager.instance.hasStoredSession()) {
      debugPrint('PushNotificationService: not signed in — parking tap');
      _pendingRoute = route;
      return;
    }

    switch (route.kind) {
      case NotificationRouteKind.chatConversation:
        await _openConversation(nav, route.conversationId!);
        break;
      case NotificationRouteKind.flaggedComment:
        nav.pushNamed(Routes.flaggedComment, arguments: route);
        break;
      case NotificationRouteKind.flaggedPost:
        nav.pushNamed(Routes.flaggedPost, arguments: route);
        break;
      case NotificationRouteKind.notificationsList:
        nav.pushNamed(Routes.notifications);
        break;
    }
  }

  /// Replays a tap that arrived while signed out. Called after a successful
  /// login so the notification the user actually tapped still lands.
  Future<void> flushPendingRoute() async {
    final pending = _pendingRoute;
    if (pending == null) return;
    _pendingRoute = null;
    await navigateTo(pending);
  }

  /// Opens the chats list, then the specific conversation on top of it so Back
  /// lands somewhere sensible.
  Future<void> _openConversation(
    NavigatorState nav,
    String conversationId,
  ) async {
    // Already looking at this conversation (e.g. a second message from the
    // same person) — don't stack another copy of the screen.
    if (getIt<ChatSocketService>().currentConversationId == conversationId) {
      return;
    }

    nav.pushNamed(Routes.chatsList);

    try {
      final conversation =
          await getIt<ChatRepo>().getConversationById(conversationId);
      // The user may have navigated away while the fetch was in flight; pushing
      // then would drop a chat screen on top of whatever they moved on to.
      if (!nav.mounted) return;
      nav.pushNamed(Routes.chatDetail, arguments: conversation);
    } catch (e) {
      // Conversation gone or unreachable — the chats list is already showing.
      debugPrint('PushNotificationService: could not open $conversationId — $e');
    }
  }

  /// Clears per-session routing state. Called on sign-out.
  void reset() {
    _foregroundMessages.clear();
    _handledMessageIds.clear();
    _pendingRoute = null;
  }
}
