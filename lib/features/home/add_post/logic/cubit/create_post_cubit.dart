import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/add_post/data/models/create_post_request_model.dart';
import 'package:riff/features/home/add_post/data/repos/create_post_repo.dart';
import 'package:riff/features/home/add_post/logic/cubit/create_post_state.dart';

class CreatePostCubit extends Cubit<CreatePostState> {
  final CreatePostRepo _createPostRepo;

  CreatePostCubit(this._createPostRepo) : super(const CreatePostState.initial());

  Future<void> createPost(
    CreatePostRequestModel requestModel, {
    List<File>? mediaFiles,
  }) async {
    emit(const CreatePostState.loading());

    final response = await _createPostRepo.createPost(
      requestModel,
      mediaFiles: mediaFiles,
    );

    response.when(
      success: (post) => emit(CreatePostState.success(post)),
      failure: (apiErrorModel) {
        debugPrint('CreatePostCubit - failure: ${apiErrorModel.errors}');
        emit(CreatePostState.failure(apiErrorModel));
      },
    );
  }
}
