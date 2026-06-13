// ignore_for_file: depend_on_referenced_packages

import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_state.freezed.dart';

@freezed
class PostState with _$PostState {
  const factory PostState.initial() = Initial;
  const factory PostState.likeLoading(String postId) = LikeLoading;
  const factory PostState.likeSuccess(String postId, bool isLiked, int likeCount) = LikeSuccess;
  const factory PostState.likeError(String message) = LikeError;
  const factory PostState.shareSuccess() = ShareSuccess;
}
