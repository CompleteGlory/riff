import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/socket_service.dart';
import '../../data/models/notification_model.dart';
import '../../data/repos/notifications_repo.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepo _repo;
  final SocketService _socket;

  Timer? _pollTimer;

  /// Broadcast stream — HomeLayout listens to show in-app banners
  final _newNotifController =
      StreamController<NotificationModel>.broadcast();
  Stream<NotificationModel> get onNewNotification => _newNotifController.stream;

  NotificationsCubit(this._repo, this._socket) : super(NotificationsInitial());

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    if (state is! NotificationsLoaded) emit(NotificationsLoading());
    try {
      final res = await _repo.getNotifications();
      if (!isClosed) emit(NotificationsLoaded(res.data, res.unreadCount));
      _startPolling();
      _tryConnectSocket();
    } catch (e) {
      if (!isClosed) emit(NotificationsError(e.toString()));
    }
  }

  // ── Soft refresh (no loading state flicker) ───────────────────────────────

  Future<void> silentRefresh() async {
    try {
      final prev = state;
      final prevUnread =
          prev is NotificationsLoaded ? prev.unreadCount : 0;
      final prevIds = prev is NotificationsLoaded
          ? prev.notifications.map((n) => n.id).toSet()
          : <int>{};

      final res = await _repo.getNotifications();
      if (isClosed) return;
      emit(NotificationsLoaded(res.data, res.unreadCount));

      // Surface newly-arrived notifications as banners
      if (res.unreadCount > prevUnread) {
        final newOnes = res.data
            .where((n) => !n.isRead && !prevIds.contains(n.id))
            .take(res.unreadCount - prevUnread);
        for (final n in newOnes) {
          _newNotifController.add(n);
        }
      }
    } catch (_) {}
  }

  // ── Polling fallback every 30 s ───────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (isClosed) return;
      final prevUnread = state is NotificationsLoaded
          ? (state as NotificationsLoaded).unreadCount
          : 0;
      try {
        final res = await _repo.getNotifications();
        if (isClosed) return;
        emit(NotificationsLoaded(res.data, res.unreadCount));
        // Surface newly-arrived notifications as banners
        if (res.unreadCount > prevUnread) {
          final newOnes = res.data
              .where((n) => !n.isRead)
              .take(res.unreadCount - prevUnread);
          for (final n in newOnes) {
            _newNotifController.add(n);
          }
        }
      } catch (_) {}
    });
  }

  // ── WebSocket real-time ───────────────────────────────────────────────────

  Future<void> _tryConnectSocket() async {
    try {
      if (_socket.isConnected) return;
      final token =
          await SharedPrefHelper.getString(SharedPrefKeys.userToken) as String;
      if (token.isEmpty) return;
      _socket.connect(token);
      _socket.on('notification', (data) {
        if (isClosed) return;
        final notif = NotificationModel.fromJson(
            Map<String, dynamic>.from(data as Map));
        _prependNotification(notif);
        _newNotifController.add(notif); // triggers in-app banner
      });
    } catch (_) {
      // socket_io_client not installed or server unreachable — polling covers it
    }
  }

  void _prependNotification(NotificationModel notif) {
    final cur = state;
    final list =
        cur is NotificationsLoaded ? cur.notifications : <NotificationModel>[];
    final updated = [notif, ...list.where((n) => n.id != notif.id)];
    final unread = updated.where((n) => !n.isRead).length;
    if (!isClosed) emit(NotificationsLoaded(updated, unread));
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> deleteAll() async {
    try {
      await _repo.deleteAllNotifications();
      if (!isClosed) emit(NotificationsLoaded([], 0));
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _repo.markAllRead();
      final cur = state;
      if (cur is NotificationsLoaded && !isClosed) {
        emit(NotificationsLoaded(
          cur.notifications.map((n) => n.copyWith(isRead: true)).toList(),
          0,
        ));
      }
    } catch (_) {}
  }

  Future<void> removeNotification(int id) async {
    // Optimistic remove from UI
    final cur = state;
    if (cur is NotificationsLoaded && !isClosed) {
      final updated = cur.notifications.where((n) => n.id != id).toList();
      emit(NotificationsLoaded(updated, updated.where((n) => !n.isRead).length));
    }
    try {
      await _repo.deleteNotification(id);
    } catch (_) {
      // If API fails, silently ignore — UI already updated
    }
  }

  /// Marks a single notification as read locally (optimistic).
  /// The server will confirm on the next poll / mark-all-read.
  void markRead(int notifId) {
    final cur = state;
    if (cur is! NotificationsLoaded || isClosed) return;
    final updated = cur.notifications
        .map((n) => n.id == notifId ? n.copyWith(isRead: true) : n)
        .toList();
    emit(NotificationsLoaded(
        updated, updated.where((n) => !n.isRead).length));
  }

  void updateFollowBackStatus(int notifId, String status) {
    final cur = state;
    if (cur is NotificationsLoaded && !isClosed) {
      emit(NotificationsLoaded(
        cur.notifications
            .map((n) =>
                n.id == notifId ? n.copyWith(followBackStatus: status) : n)
            .toList(),
        cur.unreadCount,
      ));
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _newNotifController.close();
    _socket.off('notification');
    _socket.disconnect();
    return super.close();
  }
}
