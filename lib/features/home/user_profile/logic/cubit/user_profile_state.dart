part of 'user_profile_cubit.dart';

@immutable
sealed class UserProfileState {
  const UserProfileState();

  const factory UserProfileState.initial() = UserProfileInitial;
  const factory UserProfileState.loading() = UserProfileLoading;
  const factory UserProfileState.loaded({
    required UserProfileModel profile,
    required List<Post> posts,
  }) = UserProfileLoaded;
  const factory UserProfileState.failure(String message) = UserProfileFailure;
}

class UserProfileInitial extends UserProfileState {
  const UserProfileInitial();
}

class UserProfileLoading extends UserProfileState {
  const UserProfileLoading();
}

class UserProfileLoaded extends UserProfileState {
  final UserProfileModel profile;
  final List<Post> posts;
  const UserProfileLoaded({required this.profile, required this.posts});
}

class UserProfileFailure extends UserProfileState {
  final String message;
  const UserProfileFailure(this.message);
}
