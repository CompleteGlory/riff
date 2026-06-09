// ignore_for_file: depend_on_referenced_packages
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riff/core/networks/api_error_model.dart';

part 'feed_state.freezed.dart';

@freezed
class FeedState<T> with _$FeedState<T> {
  const factory FeedState.initial() = Initial;
  const factory FeedState.loading() = Loading;
  const factory FeedState.success(T data) = Success<T>;
  const factory FeedState.failure(ApiErrorModel apiErrorModel) = Error;
}
