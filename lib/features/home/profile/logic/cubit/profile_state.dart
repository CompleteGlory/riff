part of 'profile_cubit.dart';

@immutable
sealed class ProfileState {
  const ProfileState();

  const factory ProfileState.initial() = ProfileInitial;
  const factory ProfileState.loading() = ProfileLoading;
  const factory ProfileState.success(List<Post> posts) = ProfileSuccess;
  const factory ProfileState.failure(String message) = ProfileFailure;
  const factory ProfileState.imageUploading() = ProfileImageUploading;
  const factory ProfileState.imageUploadSuccess(String imageUrl) = ProfileImageUploadSuccess;
  const factory ProfileState.imageUploadFailure(String message) = ProfileImageUploadFailure;
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileSuccess extends ProfileState {
  final List<Post> posts;
  const ProfileSuccess(this.posts);
}

class ProfileFailure extends ProfileState {
  final String message;
  const ProfileFailure(this.message);
}

class ProfileImageUploading extends ProfileState {
  const ProfileImageUploading();
}

class ProfileImageUploadSuccess extends ProfileState {
  final String imageUrl;
  const ProfileImageUploadSuccess(this.imageUrl);
}

class ProfileImageUploadFailure extends ProfileState {
  final String message;
  const ProfileImageUploadFailure(this.message);
}
