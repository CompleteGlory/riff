import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:riff/features/home/search/data/models/search_user.dart';
import 'package:riff/features/home/search/data/repos/search_repo.dart';

part 'user_search_state.dart';

/// Searching for someone to start a chat with, or to add to a group.
///
/// Both `chats_list_screen` and `create_group_screen` used to do this
/// themselves: each held a `Timer` for debouncing, a results list and a
/// loading flag in its `State`, and each called `getIt<SearchRepo>()`
/// directly. That is the same business logic written twice in two widgets —
/// and the two copies had already drifted, since only one of them debounced.
///
/// The debounce belongs here rather than in the widget because it is not a
/// presentation detail: it decides how many requests the app makes, and it has
/// to be cancelled when the search is abandoned or the cubit closes.
class UserSearchCubit extends Cubit<UserSearchState> {
  UserSearchCubit(this._repo) : super(const UserSearchState.idle());

  final SearchRepo _repo;

  /// How long typing must pause before a request goes out.
  static const debounce = Duration(milliseconds: 350);

  Timer? _debounceTimer;

  /// Rises with every query so a slow response for an older one cannot
  /// overwrite the results of a newer. Without it, typing "ali" then "alice"
  /// can leave "ali"'s results on screen if they arrive second.
  int _epoch = 0;

  /// Debounces, then searches. An empty query clears immediately and sends
  /// nothing.
  void search(String query) {
    _debounceTimer?.cancel();
    final q = query.trim();

    if (q.isEmpty) {
      _epoch++;
      emit(const UserSearchState.idle());
      return;
    }

    _debounceTimer = Timer(debounce, () => _run(q));
  }

  /// Searches immediately, skipping the debounce.
  Future<void> searchNow(String query) {
    _debounceTimer?.cancel();
    final q = query.trim();
    if (q.isEmpty) {
      _epoch++;
      emit(const UserSearchState.idle());
      return Future.value();
    }
    return _run(q);
  }

  Future<void> _run(String query) async {
    final startedAt = ++_epoch;
    if (isClosed) return;
    emit(const UserSearchState.searching());

    try {
      final results = await _repo.searchUsers(query);
      if (isClosed || startedAt != _epoch) return;
      emit(UserSearchState.results(results));
    } catch (_) {
      if (isClosed || startedAt != _epoch) return;
      // A failed search shows nothing rather than an error: the user is
      // typing, and the next keystroke will try again.
      emit(const UserSearchState.results([]));
    }
  }

  /// Clears the field's results without sending anything.
  void clear() {
    _debounceTimer?.cancel();
    _epoch++;
    if (!isClosed) emit(const UserSearchState.idle());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
