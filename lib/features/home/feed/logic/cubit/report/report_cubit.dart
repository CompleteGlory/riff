import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/repos/report_repo.dart';
import 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportRepo _repo;
  ReportCubit(this._repo) : super(ReportInitial());

  Future<void> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) async {
    emit(ReportLoading());
    final result = await _repo.reportPost(
      postId: postId,
      reason: reason,
      details: details,
    );
    result.when(
      success: (_) => emit(ReportSuccess()),
      failure: (err) => emit(ReportFailure(err.message ?? 'Failed to submit report')),
    );
  }

  Future<void> reportComment({
    required String commentId,
    required String reason,
    String? details,
  }) async {
    emit(ReportLoading());
    final result = await _repo.reportComment(
      commentId: commentId,
      reason: reason,
      details: details,
    );
    result.when(
      success: (_) => emit(ReportSuccess()),
      failure: (err) => emit(ReportFailure(err.message ?? 'Failed to submit report')),
    );
  }
}
