import 'package:flutter/material.dart';
import 'package:riff/features/commercial/data/models/ad.dart';
import 'package:riff/features/commercial/data/repos/ad_repo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:riff/generated/l10n.dart';

class AdCard extends StatefulWidget {
  final Ad ad;
  final AdRepo adRepo;

  const AdCard({super.key, required this.ad, required this.adRepo});

  @override
  State<AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<AdCard> {
  bool _viewTracked = false;

  @override
  void initState() {
    super.initState();
    _trackView();
  }

  void _trackView() {
    if (_viewTracked) return;
    _viewTracked = true;
    widget.adRepo.trackView(widget.ad.id);
  }

  Future<void> _openLink() async {
    var link = widget.ad.link;
    if (link == null || link.isEmpty) return;
    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      link = 'https://$link';
    }
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm');
  }

  String _resolve(String path) {
    if (path.startsWith('http')) return path;
    return '${ApiConstants.apiBASEURL}$path';
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    final media = ad.media ?? [];
    final storeName = ad.storeManager?.storeName ?? S.of(context).sponsored;
    final logoUrl = ad.storeManager?.storeLogo;

    final hasLink = ad.link != null && ad.link!.isNotEmpty;

    return GestureDetector(
      onTap: hasLink ? _openLink : null,

      child: Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                // Store avatar
                CircleAvatar(
                  radius: 18,
                  backgroundImage: logoUrl != null
                      ? CachedNetworkImageProvider(_resolve(logoUrl))
                      : null,
                  backgroundColor: Colors.grey.shade300,
                  child: logoUrl == null
                      ? Text(storeName[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(storeName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 1),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          S.of(context).sponsored,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Caption ─────────────────────────────────────────────────────────
          if (ad.caption != null && ad.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(ad.caption!),
            ),

          // ── Media ────────────────────────────────────────────────────────────
          if (media.isNotEmpty)
            _AdMedia(
              mediaUrls: media.map(_resolve).toList(),
              isVideo: _isVideo(media.first),
            ),

          const SizedBox(height: 8),
        ],
      ),
    ));
  }
}

// ── Media sub-widget ──────────────────────────────────────────────────────────

class _AdMedia extends StatefulWidget {
  final List<String> mediaUrls;
  final bool isVideo;

  const _AdMedia({required this.mediaUrls, required this.isVideo});

  @override
  State<_AdMedia> createState() => _AdMediaState();
}

class _AdMediaState extends State<_AdMedia> {
  VideoPlayerController? _controller;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo && widget.mediaUrls.isNotEmpty) {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrls.first))
            ..initialize().then((_) {
              if (mounted) setState(() => _videoReady = true);
              _controller!.setLooping(true);
              _controller!.play();
            });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isVideo) {
      if (!_videoReady) {
        return const AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller!),
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
      );
    }

    // Image(s) — show first only
    return CachedNetworkImage(
      imageUrl: widget.mediaUrls.first,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        height: 200,
        color: Colors.grey.shade200,
      ),
      errorWidget: (_, __, ___) => Container(
        height: 200,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
