import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/blocked_user.dart';
import '../../data/repos/block_repo.dart';

part 'block_state.dart';

class BlockCubit extends Cubit<BlockState> {
  final BlockRepo _repo;
  BlockCubit(this._repo) : super(BlockInitial());

  Future<void> loadBlockedUsers() async {
    emit(BlockLoading());
    try {
      final users = await _repo.getBlockedUsers();
      if (!isClosed) emit(BlockLoaded(users));
    } catch (e) {
      if (!isClosed) emit(BlockError(e.toString()));
    }
  }

  Future<bool> blockUser(String userId) async {
    try {
      await _repo.blockUser(userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> unblockUser(String userId) async {
    // Optimistic remove
    final cur = state;
    if (cur is BlockLoaded && !isClosed) {
      emit(BlockLoaded(cur.blockedUsers.where((u) => u.id != userId).toList()));
    }
    try { await _repo.unblockUser(userId); } catch (_) {}
  }
}
