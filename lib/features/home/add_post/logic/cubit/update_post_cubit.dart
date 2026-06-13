import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/add_post/data/repos/update_post_repo.dart';
import 'package:riff/features/home/add_post/logic/cubit/update_post_state.dart';

class UpdatePostCubit extends Cubit<UpdatePostState> {
  final UpdatePostRepo _updatePostRepo;

  UpdatePostCubit(this._updatePostRepo) : super(const UpdatePostState.initial());

  Future<void> updatePost({
    required String postId,
    required String content,
    required List<String> keepMedia,
    List<File>? newFiles,
  }) async {
    emit(const UpdatePostState.loading());

    final response = await _updatePostRepo.updatePost(
      postId: postId,
      content: content,
      keepMedia: keepMedia,
      newFiles: newFiles,
    );

    response.when(
      success: (post) => emit(UpdatePostState.success(post)),
      failure: (apiErrorModel) {
        debugPrint('UpdatePostCubit failure: ${apiErrorModel.errors}');
        emit(UpdatePostState.failure(apiErrorModel));
      },
    );
  }
}
