import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/search/data/models/search_user.dart';

abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchDiscoverLoaded extends SearchState {
  final List<Post> posts;
  final String? activeGenre;
  final String? activeInstrument;
  final bool isLoadingPosts;

  SearchDiscoverLoaded({
    required this.posts,
    this.activeGenre,
    this.activeInstrument,
    this.isLoadingPosts = false,
  });
}

class SearchResultsLoaded extends SearchState {
  final List<SearchUser> users;
  final List<Post> posts;
  final String query;

  SearchResultsLoaded({
    required this.users,
    required this.posts,
    required this.query,
  });
}

class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}
