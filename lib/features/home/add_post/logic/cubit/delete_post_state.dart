// ignore_for_file: depend_on_referenced_packages

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riff/core/networks/api_error_model.dart';

part 'delete_post_state.freezed.dart';

@freezed
class DeletePostState with _$DeletePostState {
  const factory DeletePostState.initial() = Initial;
  const factory DeletePostState.loading() = Loading;
  const factory DeletePostState.success() = Success;
  const factory DeletePostState.failure(ApiErrorModel errors) = Failure;
}
