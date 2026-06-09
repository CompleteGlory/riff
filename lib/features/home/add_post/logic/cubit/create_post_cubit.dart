import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/add_post/data/models/create_post_request_model.dart';
import 'package:riff/features/home/add_post/data/repos/create_post_repo.dart';
import 'package:riff/features/home/add_post/logic/cubit/create_post_state.dart';

class CreatePostCubit extends Cubit<CreatePostState> {
  final CreatePostRepo _createPostRepo;

  CreatePostCubit(this._createPostRepo) : super(const CreatePostState.initial());

  Future<void> createPost(CreatePostRequestModel createPostRequestModel) async {
    emit(const CreatePostState.loading());

    final response = await _createPostRepo.createPost(createPostRequestModel);

    response.when(
      success: (post) {
        // Post creation successful, emit success state with the returned Post object
        emit(CreatePostState.success(post));
      },
      failure: (apiErrorModel) {
        debugPrint('CreatePostCubit - createPost failure: ${apiErrorModel.errors.toString()}');
        // Post creation failed, emit failure state with the error model
        emit(CreatePostState.failure(apiErrorModel));
      },
    );
  }
}