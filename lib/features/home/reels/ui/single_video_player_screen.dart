import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/reels/ui/widgets/reel_item.dart';

/// Fullscreen single-video player (reel-style) launched when tapping a video
/// post from the feed or from UserProfileScreen.
class SingleVideoPlayerScreen extends StatefulWidget {
  final Post post;
  final String videoUrl;

  const SingleVideoPlayerScreen({
    super.key,
    required this.post,
    required this.videoUrl,
  });

  @override
  State<SingleVideoPlayerScreen> createState() =>
      _SingleVideoPlayerScreenState();
}

class _SingleVideoPlayerScreenState extends State<SingleVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initController();
  }

  Future<void> _initController() async {
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller = controller;
    await controller.initialize();
    controller.setLooping(true);
    controller.play();
    if (mounted) setState(() => _isReady = true);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    HomeCubit? homeCubit;
    try {
      homeCubit = context.read<HomeCubit>();
    } catch (_) {}

    final reelItem = ReelItem(
      post: widget.post,
      isActive: true,
      controller: _controller,
      isReady: _isReady,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Provide HomeCubit if available so ReelItem's like/comment/share work.
          homeCubit != null
              ? BlocProvider.value(value: homeCubit, child: reelItem)
              : reelItem,

          // Back button.
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
