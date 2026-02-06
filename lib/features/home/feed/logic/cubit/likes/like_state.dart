import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riff/core/networks/api_error_model.dart';

part 'like_state.freezed.dart';

@freezed
class LikePostState with _$LikePostState {
  const factory LikePostState.initial() = Initial;
  const factory LikePostState.loading() = Loading;
  const factory LikePostState.success(bool liked) = Success;
  const factory LikePostState.failure(ApiErrorModel errors) = Failure;
}
