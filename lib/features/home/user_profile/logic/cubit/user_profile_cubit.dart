import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart' show ApiResultPatterns;
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/follow/data/repos/follow_repo.dart';
import 'package:riff/features/home/user_profile/data/models/user_profile_model.dart';
import 'package:riff/features/home/user_profile/data/repos/user_profile_repo.dart';

part 'user_profile_state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  final UserProfileRepo _repo;
  final FollowRepo _followRepo;

  UserProfileCubit(this._repo, this._followRepo)
      : super(const UserProfileState.initial());

  Future<void> loadProfile(String userId) async {
    emit(const UserProfileState.loading());

    final profileResult = await _repo.getUserProfile(userId);
    final postsResult = await _repo.getUserPosts(userId);

    profileResult.when(
      success: (profile) {
        postsResult.when(
          success: (posts) =>
              emit(UserProfileState.loaded(profile: profile, posts: posts)),
          failure: (_) =>
              emit(UserProfileState.loaded(profile: profile, posts: [])),
        );
      },
      failure: (error) => emit(
        UserProfileState.failure(error.message ?? 'Failed to load profile'),
      ),
    );
  }

  Future<void> follow(String userId) async {
    final cur = state;
    if (cur is! UserProfileLoaded) return;
    // Optimistic: show "following" / "pending" instantly
    final optimisticStatus =
        cur.profile.isPrivate ? 'pending' : 'following';
    final optimisticDelta = optimisticStatus == 'following' ? 1 : 0;
    emit(UserProfileState.loaded(
      profile: cur.profile.copyWith(
        followStatus: optimisticStatus,
        followersCount: cur.profile.followersCount + optimisticDelta,
      ),
      posts: cur.posts,
    ));
    try {
      final status = await _followRepo.followUser(userId);
      // Correct if server disagrees (edge case)
      if (status != optimisticStatus) {
        final correctedDelta = status == 'accepted' ? 1 : 0;
        emit(UserProfileState.loaded(
          profile: cur.profile.copyWith(
            followStatus: status,
            followersCount: cur.profile.followersCount + correctedDelta,
          ),
          posts: cur.posts,
        ));
      }
    } catch (_) {
      // Revert on error
      emit(UserProfileState.loaded(
        profile: cur.profile,
        posts: cur.posts,
      ));
    }
  }

  Future<void> unfollow(String userId) async {
    final cur = state;
    if (cur is! UserProfileLoaded) return;
    // Optimistic: revert to not_following instantly
    emit(UserProfileState.loaded(
      profile: cur.profile.copyWith(
        followStatus: 'not_following',
        followersCount: (cur.profile.followersCount - 1).clamp(0, 9999999),
      ),
      posts: cur.posts,
    ));
    try {
      await _followRepo.unfollowUser(userId);
    } catch (_) {
      // Revert on error
      emit(UserProfileState.loaded(
        profile: cur.profile,
        posts: cur.posts,
      ));
    }
  }

  Future<void> removeFollower(String userId) async {
    final cur = state;
    if (cur is! UserProfileLoaded) return;
    try {
      await _followRepo.removeFollower(userId);
      emit(UserProfileState.loaded(
        profile: cur.profile.copyWith(isFollowingMe: false),
        posts: cur.posts,
      ));
    } catch (_) {}
  }
}
