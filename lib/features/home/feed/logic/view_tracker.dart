import 'package:riff/features/home/feed/data/repos/feed_repo.dart';
import 'package:riff/core/di/dependency_injection.dart';

/// Tracks post views for the current session.
/// Each post is recorded at most once per app session.
class ViewTracker {
  ViewTracker._();
  static final ViewTracker instance = ViewTracker._();

  final Set<int> _tracked = {};

  void track(int postId) {
    if (_tracked.contains(postId)) return;
    _tracked.add(postId);
    getIt<FeedRepo>().recordView(postId);
  }

  void reset() => _tracked.clear();
}
