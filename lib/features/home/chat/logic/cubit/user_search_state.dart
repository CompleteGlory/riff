part of 'user_search_cubit.dart';

/// What the user-search field is currently showing.
///
/// Three states rather than a list plus a bool: "nothing typed yet" and
/// "searched and found nobody" look identical to a widget holding only a list,
/// and they should not — one shows a prompt, the other shows "no results".
class UserSearchState {
  /// Nothing typed, or the field was cleared.
  const UserSearchState.idle()
      : isSearching = false,
        results = const [],
        hasQuery = false;

  /// A request is in flight.
  const UserSearchState.searching()
      : isSearching = true,
        results = const [],
        hasQuery = true;

  /// A search finished. [results] may legitimately be empty.
  const UserSearchState.results(this.results)
      : isSearching = false,
        hasQuery = true;

  final bool isSearching;
  final List<SearchUser> results;

  /// True once a query has been issued, so the UI can tell "type to search"
  /// from "nobody matched".
  final bool hasQuery;

  bool get isEmptyResult => hasQuery && !isSearching && results.isEmpty;
}
