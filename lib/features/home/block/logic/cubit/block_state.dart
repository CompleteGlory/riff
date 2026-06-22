part of 'block_cubit.dart';

abstract class BlockState {}

class BlockInitial  extends BlockState {}
class BlockLoading  extends BlockState {}
class BlockError    extends BlockState { final String message; BlockError(this.message); }

class BlockLoaded extends BlockState {
  final List<BlockedUser> blockedUsers;
  BlockLoaded(this.blockedUsers);
}
