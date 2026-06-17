abstract class FeatureRequestState {}

class FeatureRequestInitial extends FeatureRequestState {}

class FeatureRequestLoading extends FeatureRequestState {}

class FeatureRequestSuccess extends FeatureRequestState {}

class FeatureRequestFailure extends FeatureRequestState {
  final String message;
  FeatureRequestFailure(this.message);
}
