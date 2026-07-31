import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/logic/app_scoped_cubit.dart';
import 'package:riff/core/networks/socket_service.dart';
import '../../data/models/notification_model.dart';
import '../../data/repos/notifications_repo.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState>
    with AppScopedCubit<NotificationsState> {
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
      // Register the handler before connecting: SocketService replays its
      // handlers onto every new socket, so this survives reconnects too.
      _socket.on('notification', (data) {
        if (isClosed) return;
        final notif = NotificationModel.fromJson(
            Map<String, dynamic>.from(data as Map));
        _prependNotification(notif);
        _newNotifController.add(notif); // triggers in-app banner
      });
      // ensureConnected() refreshes an expired access token first — the
      // handshake is rejected outright by the gateway otherwise.
      await _socket.ensureConnected();
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

  // ── Reset (call on logout) ────────────────────────────────────────────────

  /// Cancels polling, disconnects socket, and wipes state.
  /// Call this before navigating to login so the next user starts clean.
  void reset() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _socket.off('notification');
    _socket.disconnect();
    if (!isClosed) emit(NotificationsInitial());
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> deleteAll() async {
    try {
      await _repo.deleteAllNotifications();
      if (!isClosed) emit(NotificationsLoaded([], 0));
    } catch (_) {}
  }

  /// Marks everything read.
  ///
  /// Optimistic: the list clears immediately and only rolls back if the server
  /// rejects it. The previous version emitted *after* awaiting the request and
  /// swallowed every error, so a failed call looked identical to a successful
  /// one — the badge just stayed put with no explanation.
  ///
  /// Returns true when the server confirmed.
  Future<bool> markAllRead() async {
    if (isClosed) return false;

    final previous = state;
    if (previous is NotificationsLoaded) {
      emit(NotificationsLoaded(
        previous.notifications.map((n) => n.copyWith(isRead: true)).toList(),
        0,
      ));
    }

    try {
      await _repo.markAllRead();
      return true;
    } catch (_) {
      if (!isClosed && previous is NotificationsLoaded) emit(previous);
      return false;
    }
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
    // Ignore route-scoped disposal (see AppScopedCubit) — tearing the polling
    // timer and socket down here used to permanently break notifications for
    // the rest of the session.
    if (!isPermanentlyClosing) return Future<void>.value();
    _pollTimer?.cancel();
    _newNotifController.close();
    _socket.off('notification');
    _socket.disconnect();
    return super.close();
  }
}
