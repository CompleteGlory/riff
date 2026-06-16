import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repos/follow_repo.dart';

part 'follow_state.dart';

class FollowCubit extends Cubit<FollowState> {
  final FollowRepo _repo;

  FollowCubit(this._repo) : super(FollowInitial());

  /// initialStatus: 'not_following' | 'pending' | 'following'
  void setStatus(String status) => emit(FollowSuccess(status));

  Future<void> follow(String userId) async {
    final prev = state;
    emit(FollowLoading());
    try {
      final status = await _repo.followUser(userId);
      emit(FollowSuccess(status));
    } catch (e) {
      emit(prev is FollowSuccess ? prev : FollowSuccess('not_following'));
    }
  }

  Future<void> unfollow(String userId) async {
    final prev = state;
    emit(FollowLoading());
    try {
      await _repo.unfollowUser(userId);
      emit(FollowSuccess('not_following'));
    } catch (e) {
      emit(prev is FollowSuccess ? prev : FollowSuccess('following'));
    }
  }

  Future<bool> acceptFollow(String userId) async {
    try {
      await _repo.acceptFollow(userId);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> rejectFollow(String userId) async {
    try {
      await _repo.rejectFollow(userId);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> removeFollower(String userId) async {
    try {
      await _repo.removeFollower(userId);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> updatePrivacy(bool isPrivate) async {
    try {
      await _repo.updatePrivacy(isPrivate);
      return true;
    } catch (_) { return false; }
  }
}
