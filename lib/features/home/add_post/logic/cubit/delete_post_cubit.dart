import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/logic/post_events.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/add_post/data/repos/delete_post_repo.dart';
import 'package:riff/features/home/add_post/logic/cubit/delete_post_state.dart';

class DeletePostCubit extends Cubit<DeletePostState> {
  final DeletePostRepo _deletePostRepo;

  DeletePostCubit(this._deletePostRepo) : super(const DeletePostState.initial());

  Future<void> deletePost(String postId) async {
    emit(const DeletePostState.loading());

    final response = await _deletePostRepo.deletePost(postId);

    response.when(
      success: (_) {
        // Tell every list holding this post to drop it — the feed, reels,
        // discover and the author's profile each own their own copy.
        PostEvents.notifyDeleted(postId);
        emit(const DeletePostState.success());
      },
      failure: (apiErrorModel) {
        debugPrint('DeletePostCubit - deletePost failure: ${apiErrorModel.errors.toString()}');
        // Post deletion failed
        emit(DeletePostState.failure(apiErrorModel));
      },
    );
  }
}
