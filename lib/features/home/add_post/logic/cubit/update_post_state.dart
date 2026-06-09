import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/features/home/feed/data/models/post.dart';

part 'update_post_state.freezed.dart';

@freezed
class UpdatePostState with _$UpdatePostState {
  const factory UpdatePostState.initial() = Initial;
  const factory UpdatePostState.loading() = Loading;
  const factory UpdatePostState.success(Post post) = Success;
  const factory UpdatePostState.failure(ApiErrorModel errors) = Failure;
}
