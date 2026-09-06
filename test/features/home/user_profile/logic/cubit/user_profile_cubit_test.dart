import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/follow/data/repos/follow_repo.dart';
import 'package:riff/features/home/user_profile/data/models/user_profile_model.dart';
import 'package:riff/features/home/user_profile/data/repos/user_profile_repo.dart';
import 'package:riff/features/home/user_profile/logic/cubit/user_profile_cubit.dart';

import 'user_profile_cubit_test.mocks.dart';

/// See user_profile_cubit_test.md for what this covers and why.
@GenerateMocks([UserProfileRepo, FollowRepo])
void main() {
  late MockUserProfileRepo repo;
  late MockFollowRepo followRepo;
  late UserProfileCubit cubit;

  const profile = UserProfileModel(
    id: 'u1',
    fullName: 'Alice A',
    username: 'alice',
    postsCount: 0,
    followersCount: 0,
    followingCount: 0,
  );

  setUp(() {
    repo = MockUserProfileRepo();
    followRepo = MockFollowRepo();
    cubit = UserProfileCubit(repo, followRepo);
  });

  test('loads a profile with its posts', () async {
    when(repo.getUserProfile('u1'))
        .thenAnswer((_) async => ApiResult.success(profile));
    when(repo.getUserPosts('u1')).thenAnswer((_) async => ApiResult.success([]));

    await cubit.loadProfile('u1');

    expect(cubit.state, isA<UserProfileLoaded>());
  });

  test('does not emit after the screen is closed mid-load', () async {
    // The reported crash: StateError, "Cannot emit new states after calling
    // close" — fatal, 3 users. loadProfile awaits twice, so backing out of a
    // profile before both requests land closes the cubit while its result
    // handlers are still queued.
    final profileCall = Completer<ApiResult<UserProfileModel>>();
    when(repo.getUserProfile('u1')).thenAnswer((_) => profileCall.future);
    when(repo.getUserPosts('u1')).thenAnswer((_) async => ApiResult.success([]));

    final loading = cubit.loadProfile('u1');
    await cubit.close();
    profileCall.complete(ApiResult.success(profile));

    // Without the guard this throws out of the awaited future rather than
    // failing an assertion — the emit is reached, not merely attempted.
    await expectLater(loading, completes);
  });

  test('does not emit after close when the profile request fails', () async {
    // The failure branch emits too, and had the same gap.
    final profileCall = Completer<ApiResult<UserProfileModel>>();
    when(repo.getUserProfile('u1')).thenAnswer((_) => profileCall.future);
    when(repo.getUserPosts('u1')).thenAnswer((_) async => ApiResult.success([]));

    final loading = cubit.loadProfile('u1');
    await cubit.close();
    profileCall.complete(ApiResult.failure(ApiErrorModel(message: 'nope')));

    await expectLater(loading, completes);
  });
}
