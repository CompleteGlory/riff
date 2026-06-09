import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riff/core/networks/api_error_model.dart';

part 'comment_state.freezed.dart';

@freezed
class CommentState<T> with _$CommentState<T> {
  const factory CommentState.initial() = Initial;
  const factory CommentState.loading() = Loading;
  const factory CommentState.success(T data) = Success<T>;
  const factory CommentState.failure(ApiErrorModel apiErrorModel) = Error;
}
