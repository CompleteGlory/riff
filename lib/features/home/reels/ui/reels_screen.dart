// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/reels/logic/cubit/reels_cubit.dart';
import 'package:riff/features/home/reels/logic/cubit/reels_state.dart';
import 'package:riff/features/home/reels/ui/widgets/reel_item.dart';

class ReelsScreen extends StatelessWidget {
  /// When provided the reel list starts with this post (index 0) and the rest
  /// of the fetched reels follow after it.
  final Post? initialPost;

  const ReelsScreen({super.key, this.initialPost});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReelsCubit>()..loadReels(),
      child: _ReelsBody(initialPost: initialPost),
    );
  }
}

class _ReelsBody extends StatefulWidget {
  final Post? initialPost;
  const _ReelsBody({this.initialPost});

  @override
  State<_ReelsBody> createState() => _ReelsBodyState();
}

class _ReelsBodyState extends State<_ReelsBody> {
  final PageController _pageController = PageController(keepPage: true);
  int _currentPage = 0;

  // --- 5-slot controller cache (currentPage ± 2) ---
  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, bool> _ready = {};
  List<Post> _reels = [];

  @override
  void initState() {
    super.initState();
    // Seed the list with the tapped post so the video starts loading immediately
    // before the API reels arrive.
    if (widget.initialPost != null) {
      _reels = [widget.initialPost!];
      _initController(0);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  // Called whenever the BLoC delivers a new (or unchanged) reels list.
  void _onReelsUpdated(List<Post> newReels) {
    final initialPost = widget.initialPost;
    List<Post> merged;

    if (initialPost != null) {
      // Keep initialPost at index 0; append all other reels after it (deduped).
      final rest = newReels.where((r) => r.id != initialPost.id).toList();
      merged = [initialPost, ...rest];
    } else {
      merged = newReels;
    }

    if (merged.length == _reels.length) return; // nothing new
    _reels = merged;
    _syncCache();
  }

  // Keep controllers alive for [currentPage-2 … currentPage+2].
  void _syncCache() {
    if (_reels.isEmpty) return;
    final min = (_currentPage - 2).clamp(0, _reels.length - 1);
    final max = (_currentPage + 2).clamp(0, _reels.length - 1);

    // Dispose out-of-range controllers.
    for (final k in _controllers.keys.where((k) => k < min || k > max).toList()) {
      _controllers.remove(k)!.dispose();
      _ready.remove(k);
    }

    // Initialize any missing controllers in range.
    for (var i = min; i <= max; i++) {
      if (!_controllers.containsKey(i)) _initController(i);
    }

    // Sync play / pause state.
    _syncPlayback();
  }

  void _syncPlayback() {
    for (final entry in _controllers.entries) {
      if (_ready[entry.key] != true) continue;
      if (entry.key == _currentPage) {
        if (!entry.value.value.isPlaying) entry.value.play();
      } else {
        if (entry.value.value.isPlaying) entry.value.pause();
        // Reset to first frame so thumbnail is visible instead of black.
        entry.value.seekTo(Duration.zero);
      }
    }
  }

  Future<void> _initController(int index) async {
    if (index >= _reels.length) return;
    final url = _videoUrl(_reels[index]);
    if (url == null) return;

    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _controllers[index] = c;
    _ready[index] = false;

    await c.initialize();
    c.setLooping(true);

    // Guard: make sure this is still the current controller for this slot.
    if (mounted && _controllers[index] == c) {
      setState(() => _ready[index] = true);
      if (_currentPage == index) {
        c.play();
      } else {
        // Seek to first frame so the thumbnail is visible instead of black.
        await c.seekTo(Duration.zero);
      }
    }
  }

  String? _videoUrl(Post post) {
    for (final m in post.media ?? []) {
      final lower = m.toLowerCase();
      if (lower.endsWith('.mp4') ||
          lower.endsWith('.mov') ||
          lower.endsWith('.webm') ||
          lower.endsWith('.avi') ||
          lower.endsWith('.mkv')) {
        return m.startsWith('/') ? '${ApiConstants.apiBASEURL}$m' : m;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReelsCubit, ReelsState>(
      builder: (context, state) {
        // Collect the latest reels from the state.
        final incoming = switch (state) {
          ReelsSuccess s => s.reels,
          ReelsLoadingMore s => s.reels,
          _ => <Post>[],
        };

        // Sync controller cache post-frame so we don't call setState during build.
        if (incoming.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _onReelsUpdated(incoming);
          });
        }

        // Show full-screen spinner on the very first load only if we have nothing
        // seeded yet (no initialPost was provided).
        if (_reels.isEmpty && state is! ReelsFailure) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        // Show error only when there is nothing to display yet.
        if (state is ReelsFailure && _reels.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        context.read<ReelsCubit>().loadReels(refresh: true),
                    child: const Text('Retry',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        // Empty state (no reels at all).
        if (_reels.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'No reels yet.\nPost a video to get started!',
                style: TextStyle(color: Colors.white54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: RefreshIndicator(
            onRefresh: () async {
              // Dispose all cached controllers and reset to page 0.
              for (final c in _controllers.values) {
                c.dispose();
              }
              _controllers.clear();
              _ready.clear();
              setState(() => _currentPage = 0);
              _pageController.jumpToPage(0);
              await context.read<ReelsCubit>().loadReels(refresh: true);
              // Re-seed with initialPost if present so index 0 is preserved.
              final ip = widget.initialPost;
              if (ip != null) {
                _reels = [ip];
                _initController(0);
              }
            },
            color: Colors.white,
            backgroundColor: Colors.black87,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _reels.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _syncCache();
                if (index >= _reels.length - 3) {
                  context.read<ReelsCubit>().loadReels();
                }
              },
              itemBuilder: (context, index) => ReelItem(
                key: ValueKey(_reels[index].id),
                post: _reels[index],
                isActive: index == _currentPage,
                controller: _controllers[index],
                isReady: _ready[index] == true,
                showBackButton: widget.initialPost != null,
              ),
            ),
          ),
        );
      },
    );
  }
}
