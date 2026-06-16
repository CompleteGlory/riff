part of 'notifications_cubit.dart';

abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}
class NotificationsLoading extends NotificationsState {}
class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  NotificationsLoaded(this.notifications, this.unreadCount);
}
class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
}
