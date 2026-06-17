import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/core/data/repos/feedback_repo.dart';
import 'bug_report_state.dart';

class BugReportCubit extends Cubit<BugReportState> {
  final FeedbackRepo _repo;
  BugReportCubit(this._repo) : super(BugReportInitial());

  Future<void> submit({
    required String title,
    required String description,
    String? stepsToReproduce,
    String severity = 'Medium',
  }) async {
    emit(BugReportLoading());
    final result = await _repo.reportBug(
      title: title,
      description: description,
      stepsToReproduce: stepsToReproduce,
      severity: severity,
    );
    result.when(
      success: (_) => emit(BugReportSuccess()),
      failure: (err) => emit(BugReportFailure(err.message ?? 'Failed to submit')),
    );
  }
}
