import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/features/home/feed/data/repos/feed_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/feed_state.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/models/posts_response.dart';

class FeedCubit extends Cubit<FeedState> {
  final FeedRepo _feedRepo;

  FeedCubit(this._feedRepo) : super(const FeedState.initial());

  int page = 1;
  final int limit = 10;

  Future<void> getPosts({bool refresh = false}) async {
    if (refresh) page = 1;

    emit(const FeedState.loading());

    final response = await _feedRepo.getPosts(page, limit);

    response.when(
      success: (PostsResponse data) {
        emit(FeedState.success(data));
        page++;
      },
      failure: (apiErrorModel) {
          print("error in cubit");
        emit(FeedState.failure(apiErrorModel));
      },
    );
  }
}
