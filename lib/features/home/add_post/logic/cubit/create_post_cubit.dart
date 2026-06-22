import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/services/upload_progress_service.dart';
import 'package:riff/features/home/add_post/data/models/create_post_request_model.dart';
import 'package:riff/features/home/add_post/data/repos/create_post_repo.dart';
import 'package:riff/features/home/add_post/logic/cubit/create_post_state.dart';

class CreatePostCubit extends Cubit<CreatePostState> {
  final CreatePostRepo _createPostRepo;

  CreatePostCubit(this._createPostRepo) : super(const CreatePostState.initial());

  /// True while a multipart upload is in flight.
  /// Guards against double-submits and prevents [reset] from clearing state
  /// while an upload is still running.
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  Future<void> createPost(
    CreatePostRequestModel requestModel, {
    List<File>? mediaFiles,
  }) async {
    if (_isUploading) return; // ignore double-tap
    _isUploading = true;
    emit(const CreatePostState.loading());

    final response = await _createPostRepo.createPost(
      requestModel,
      mediaFiles: mediaFiles,
      onProgress: (progress) {
        if (!isClosed) {
          emit(CreatePostState.uploading(progress));
          UploadProgressService.instance.setProgress(progress);
        }
      },
    );

    _isUploading = false;
    // Always clear the global overlay on completion
    UploadProgressService.instance.setProgress(null);

    if (isClosed) return;

    response.when(
      success: (post) => emit(CreatePostState.success(post)),
      failure: (apiErrorModel) {
        debugPrint('CreatePostCubit - failure: ${apiErrorModel.errors}');
        emit(CreatePostState.failure(apiErrorModel));
      },
    );
  }

  /// Reset to the initial state so the create-post form is blank for the
  /// next use.  No-op while an upload is in flight.
  void reset() {
    if (_isUploading) return;
    if (!isClosed) emit(const CreatePostState.initial());
  }
}
