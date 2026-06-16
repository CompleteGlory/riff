import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/features/home/notifications/logic/cubit/notifications_cubit.dart';
import 'package:riff/features/home/notifications/UI/notifications_screen.dart';
import 'package:riff/features/home/notifications/UI/flagged_comment_detail_screen.dart';
import 'package:riff/features/home/notifications/UI/flagged_post_detail_screen.dart';

/// Handles FCM token registration and push notification display / routing.
///
/// Tap routing (foreground banner, background tap, terminated tap):
///   admin_notice + comment_id  → FlaggedCommentDetailScreen
///   post_flagged / admin_notice + post_id → FlaggedPostDetailScreen
///   everything else            → NotificationsScreen
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  /// Wire into MaterialApp.navigatorKey for context-free navigation.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// HomeLayout subscribes to this and calls silentRefresh() so the badge and
  /// list update the moment a foreground FCM message arrives — no restart needed.
  static final _refreshController = StreamController<void>.broadcast();
  static Stream<void> get refreshStream => _refreshController.stream;

  final _fcm = FirebaseMessaging.instance;
  final _localNotifs = FlutterLocalNotificationsPlugin();

  static const _channelId = 'riff_default';
  static const _channelName = 'Riff Notifications';

  /// Stash the last foreground FCM message so the local-notification tap
  /// handler can deep-link to the correct detail screen.
  RemoteMessage? _pendingForegroundMessage;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _requestPermission();
    await _setupLocalNotifications();
    await _registerToken();
    _listenForeground();
    _listenTokenRefresh();
    _listenBackgroundTap();
    await _checkTerminatedTap();
  }

  // ── Permission ────────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  // ── Local notifications (foreground display) ──────────────────────────────

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifs.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (_) {
        // User tapped the foreground local banner — route using the stashed msg.
        final pending = _pendingForegroundMessage;
        _pendingForegroundMessage = null;
        if (pending != null) {
          _navigateFromMessage(pending);
        } else {
          _navigateToNotifications();
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
      final userToken =
          await SharedPrefHelper.getString(SharedPrefKeys.userToken);
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
      // Keep for tap routing.
      _pendingForegroundMessage = message;

      final notification = message.notification;
      if (notification != null) {
        _localNotifs.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
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
    FirebaseMessaging.onMessageOpenedApp.listen(_navigateFromMessage);
  }

  // ── Terminated tap ────────────────────────────────────────────────────────

  Future<void> _checkTerminatedTap() async {
    final message = await _fcm.getInitialMessage();
    if (message != null) {
      // Give the widget tree time to build before pushing a route.
      Future.delayed(
        const Duration(milliseconds: 800),
        () => _navigateFromMessage(message),
      );
    }
  }

  // ── Smart router ──────────────────────────────────────────────────────────

  void _navigateFromMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['notification_type'] as String?;
    final commentIdStr = data['comment_id'] as String?;
    final postIdStr = data['post_id'] as String?;

    // Flagged comment notification → go straight to the comment detail screen.
    if ((type == 'comment_flagged' || (type == 'admin_notice' && commentIdStr != null))) {
      _navigateToCommentDetail(
        commentId: int.tryParse(commentIdStr!),
        postId: postIdStr != null ? int.tryParse(postIdStr) : null,
        title: message.notification?.title ?? data['title'] as String?,
        body: message.notification?.body ?? data['body'] as String?,
      );
      return;
    }

    // Flagged post or admin notice about a post → post detail screen.
    if ((type == 'post_flagged' || type == 'admin_notice') &&
        postIdStr != null) {
      _navigateToPostDetail(
        postId: int.tryParse(postIdStr),
        title: message.notification?.title ?? data['title'] as String?,
        body: message.notification?.body ?? data['body'] as String?,
      );
      return;
    }

    // Like, comment, follow, etc. → notifications list.
    _navigateToNotifications();
  }

  // ── Navigation targets ────────────────────────────────────────────────────

  void _navigateToNotifications() {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => getIt<NotificationsCubit>()..load(),
        child: const NotificationsScreen(),
      ),
    ));
  }

  void _navigateToCommentDetail({
    int? commentId,
    int? postId,
    String? title,
    String? body,
  }) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
      builder: (_) => FlaggedCommentDetailScreen(
        commentId: commentId,
        postId: postId,
        flagTitle: title,
        flagBody: body,
      ),
    ));
  }

  void _navigateToPostDetail({
    int? postId,
    String? title,
    String? body,
  }) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
      builder: (_) => FlaggedPostDetailScreen(
        postId: postId,
        flagTitle: title,
        flagBody: body,
      ),
    ));
  }
}
