import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/profile/data/repos/profile_repo.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepo _repo;
  List<Post> _posts = [];

  ProfileCubit(this._repo) : super(const ProfileState.initial());

  List<Post> get posts => _posts;

  Future<void> loadUserPosts(String userId) async {
    emit(const ProfileState.loading());
    final result = await _repo.getUserPosts(userId);
    result.when(
      success: (posts) {
        _posts = posts;
        emit(ProfileState.success(posts));
      },
      failure: (error) =>
          emit(ProfileState.failure(error.message ?? 'Failed to load posts')),
    );
  }

  Future<void> uploadProfileImage(File file) async {
    emit(const ProfileState.imageUploading());
    final result = await _repo.uploadProfileImage(file);
    result.when(
      success: (url) => emit(ProfileState.imageUploadSuccess(url)),
      failure: (error) => emit(
        ProfileState.imageUploadFailure(error.message ?? 'Upload failed'),
      ),
    );
  }
}
