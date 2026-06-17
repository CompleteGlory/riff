import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/core/data/repos/feedback_repo.dart';
import 'feature_request_state.dart';

class FeatureRequestCubit extends Cubit<FeatureRequestState> {
  final FeedbackRepo _repo;
  FeatureRequestCubit(this._repo) : super(FeatureRequestInitial());

  Future<void> submit({
    required String title,
    required String description,
    String? motivation,
  }) async {
    emit(FeatureRequestLoading());
    final result = await _repo.requestFeature(
      title: title,
      description: description,
      motivation: motivation,
    );
    result.when(
      success: (_) => emit(FeatureRequestSuccess()),
      failure: (err) => emit(FeatureRequestFailure(err.message ?? 'Failed to submit')),
    );
  }
}
