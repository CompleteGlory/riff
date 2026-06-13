// ignore_for_file: depend_on_referenced_packages

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/features/home/feed/data/models/post.dart';

part 'create_post_state.freezed.dart';

@freezed
class CreatePostState with _$CreatePostState {
  const factory CreatePostState.initial() = _Initial;
  const factory CreatePostState.loading() = Loading;
  const factory CreatePostState.success(Post post) = Success;
  const factory CreatePostState.failure(ApiErrorModel apiErrorModel) = Failure;
}