import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/reels/data/repos/reels_repo.dart';
import 'package:riff/features/home/reels/logic/cubit/reels_state.dart';

class ReelsCubit extends Cubit<ReelsState> {
  final ReelsRepo _reelsRepo;

  ReelsCubit(this._reelsRepo) : super(const ReelsInitial());

  int _page = 1;
  final int _limit = 10;
  final List<Post> _reels = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadReels({bool refresh = false}) async {
    if (_isLoadingMore) return;
    if (!refresh && !_hasMore) return; // nothing more to fetch

    if (refresh) {
      _page = 1;
      _reels.clear();
      _hasMore = true;
      emit(const ReelsLoading());
    } else if (_page == 1) {
      emit(const ReelsLoading());
    } else {
      _isLoadingMore = true;
      emit(ReelsLoadingMore(reels: List.from(_reels)));
    }

    final result = await _reelsRepo.getReels(_page, _limit);

    result.when(
      success: (data) {
        final newReels = data.data
            .where((r) => !_reels.any((e) => e.id == r.id))
            .toList();
        _reels.addAll(newReels);
        _isLoadingMore = false;
        _page++;
        _hasMore = _page <= data.pagination.totalPages;
        emit(ReelsSuccess(reels: List.from(_reels), hasMore: _hasMore));
      },
      failure: (err) {
        _isLoadingMore = false;
        emit(ReelsFailure(err.message ?? 'Failed to load reels'));
      },
    );
  }
}
