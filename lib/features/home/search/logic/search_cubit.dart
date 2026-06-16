import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/features/home/search/data/repos/search_repo.dart';
import 'package:riff/features/home/search/logic/search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepo _repo;
  Timer? _debounce;

  SearchCubit(this._repo) : super(SearchInitial());

  /// Called on screen init — loads personalised discover feed
  Future<void> loadDiscover({String? genre, String? instrument}) async {
    final currentState = state;
    if (currentState is SearchDiscoverLoaded) {
      emit(
        SearchDiscoverLoaded(
          posts: currentState.posts,
          activeGenre: genre,
          activeInstrument: instrument,
          isLoadingPosts: true,
        ),
      );
    } else {
      emit(SearchLoading());
    }
    try {
      final posts = await _repo.discoverPosts(
        genre: genre,
        instrument: instrument,
      );
      emit(
        SearchDiscoverLoaded(
          posts: posts,
          activeGenre: genre,
          activeInstrument: instrument,
        ),
      );
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  /// Called on every keystroke — debounced 400 ms
  void onQueryChanged(String q) {
    _debounce?.cancel();

    if (q.trim().isEmpty) {
      loadDiscover();
      return;
    }

    emit(SearchLoading());

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final users = await _repo.searchUsers(q);
        final posts = await _repo.searchPosts(q);
        emit(SearchResultsLoaded(users: users, posts: posts, query: q));
      } catch (e) {
        emit(SearchError(e.toString()));
      }
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
