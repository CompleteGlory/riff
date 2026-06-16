part of 'follow_cubit.dart';

abstract class FollowState {}

class FollowInitial extends FollowState {}

class FollowLoading extends FollowState {}

/// status: 'not_following' | 'pending' | 'following'
class FollowSuccess extends FollowState {
  final String status;
  FollowSuccess(this.status);
}

class FollowError extends FollowState {
  final String message;
  FollowError(this.message);
}
