import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart' show ApiResultPatterns;
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/user_profile/data/models/user_profile_model.dart';
import 'package:riff/features/home/user_profile/data/repos/user_profile_repo.dart';

part 'user_profile_state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  final UserProfileRepo _repo;

  UserProfileCubit(this._repo) : super(const UserProfileState.initial());

  Future<void> loadProfile(String userId) async {
    emit(const UserProfileState.loading());

    final profileResult = await _repo.getUserProfile(userId);
    final postsResult = await _repo.getUserPosts(userId);

    profileResult.when(
      success: (profile) {
        postsResult.when(
          success: (posts) => emit(UserProfileState.loaded(profile: profile, posts: posts)),
          failure: (_) => emit(UserProfileState.loaded(profile: profile, posts: [])),
        );
      },
      failure: (error) => emit(
        UserProfileState.failure(error.message ?? 'Failed to load profile'),
      ),
    );
  }
}
