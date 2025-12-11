import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/add_post/data/models/create_post_request_model.dart';
import 'package:riff/features/home/add_post/data/repos/update_post_repo.dart';
import 'package:riff/features/home/add_post/logic/cubit/update_post_state.dart';

class UpdatePostCubit extends Cubit<UpdatePostState> {
  final UpdatePostRepo _updatePostRepo;

  UpdatePostCubit(this._updatePostRepo) : super(const UpdatePostState.initial());

  Future<void> updatePost(
    String postId,
    CreatePostRequestModel updatePostRequestModel,
  ) async {
    emit(const UpdatePostState.loading());

    final response = await _updatePostRepo.updatePost(postId, updatePostRequestModel);

    response.when(
      success: (post) {
        // Post update successful, emit success state with the returned Post object
        emit(UpdatePostState.success(post));
      },
      failure: (apiErrorModel) {
        debugPrint('UpdatePostCubit - updatePost failure: ${apiErrorModel.errors.toString()}');
        // Post update failed, emit failure state with the error model
        emit(UpdatePostState.failure(apiErrorModel));
      },
    );
  }
}
