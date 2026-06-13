import 'package:riff/features/home/feed/data/models/post.dart';

abstract class ReelsState {
  const ReelsState();
}

class ReelsInitial extends ReelsState {
  const ReelsInitial();
}

class ReelsLoading extends ReelsState {
  const ReelsLoading();
}

class ReelsSuccess extends ReelsState {
  final List<Post> reels;
  final bool hasMore;
  const ReelsSuccess({required this.reels, required this.hasMore});
}

class ReelsLoadingMore extends ReelsState {
  final List<Post> reels;
  const ReelsLoadingMore({required this.reels});
}

class ReelsFailure extends ReelsState {
  final String message;
  const ReelsFailure(this.message);
}
