import 'dart:math' as math show sin, pi;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/social_share/data/models/spotify_now_playing.dart';
import 'package:riff/features/social_share/data/repos/spotify_now_playing_repo.dart';
import 'package:riff/features/social_share/services/platform_share_service.dart';
import 'package:riff/features/social_share/services/spotify_auth_service.dart';

class NowPlayingCard extends StatefulWidget {
  final bool isOwnProfile;

  /// When viewing another user's profile, pass their userId so the card
  /// fetches their now-playing via the backend instead of the current user's.
  final String? userId;

  const NowPlayingCard({super.key, this.isOwnProfile = false, this.userId});

  @override
  State<NowPlayingCard> createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends State<NowPlayingCard>
    with TickerProviderStateMixin {
  static const _green = Color(0xFF1DB954);

  final _repo = SpotifyNowPlayingRepo();

  bool _connected  = false;
  bool _loading    = true;
  bool _connecting = false; // true only while OAuth is in flight
  SpotifyNowPlaying? _track;

  late final AnimationController _pulseCtrl;
  late final AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _init();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (widget.isOwnProfile) {
      _connected = await SpotifyAuthService.instance.isConnected;
      if (_connected) _track = await _repo.fetch();
    } else if (widget.userId != null) {
      // Fetch the other user's now-playing from the backend.
      _connected = true; // skip connect-prompt for other users
      _track = await _repo.fetchForUser(widget.userId!);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _connect() async {
    setState(() { _loading = true; _connecting = true; });
    final ok = await SpotifyAuthService.instance.connect();
    if (ok) {
      _connected = true;
      _track = await _repo.fetch();
    }
    if (mounted) setState(() { _loading = false; _connecting = false; });
  }

  Future<void> _disconnect() async {
    await SpotifyAuthService.instance.disconnect();
    if (mounted) setState(() { _connected = false; _track = null; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _connecting ? _buildConnectingAnimation() : _buildSkeleton();
    }
    if (!_connected && widget.isOwnProfile) return _buildConnectPrompt();
    if (_track == null) return const SizedBox.shrink();
    return _buildTrackCard(_track!);
  }

  // ─── Initial skeleton (checking if already connected) ───────────────────

  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        height: 72.h,
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFF121212),
            const Color(0xFF1A1A1A),
            _pulseCtrl.value,
          ),
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
    );
  }

  // ─── OAuth in-flight animation ───────────────────────────────────────────

  Widget _buildConnectingAnimation() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(vertical: 24.h),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _green.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing ring + Spotify logo
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) {
              final scale = 1.0 + _pulseCtrl.value * 0.12;
              final opacity = 1.0 - _pulseCtrl.value * 0.5;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 64.r, height: 64.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _green.withValues(alpha: opacity),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  // Second ring
                  Transform.scale(
                    scale: scale * 1.2,
                    child: Container(
                      width: 64.r, height: 64.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _green.withValues(alpha: opacity * 0.4),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  // Spotify logo
                  child!,
                ],
              );
            },
            child: _SpotifyIcon(size: 64.r),
          ),

          SizedBox(height: 16.h),

          Text(
            'Connecting to Spotify',
            style: TextStyles.font14Medium.copyWith(color: Colors.white),
          ),
          SizedBox(height: 6.h),

          // Animated dots
          AnimatedBuilder(
            animation: _dotsCtrl,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i / 3.0;
                final t = (_dotsCtrl.value - delay).clamp(0.0, 1.0);
                final bounce = math.sin(t * math.pi);
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: Transform.translate(
                    offset: Offset(0, -4 * bounce),
                    child: Container(
                      width: 6.r, height: 6.r,
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.4 + 0.6 * bounce),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: 4.h),
          Text(
            'Approve access in the browser',
            style: TextStyles.font12regular.copyWith(
              color: const Color(0xFF888888),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Connect prompt ──────────────────────────────────────────────────────

  Widget _buildConnectPrompt() {
    return GestureDetector(
      onTap: _connect,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _green.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          _SpotifyIcon(size: 42.r),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect Spotify',
                  style: TextStyles.font14Medium.copyWith(color: Colors.white),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Show what you\'re listening to',
                  style: TextStyles.font12regular
                      .copyWith(color: const Color(0xFFAAAAAA)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _green),
        ]),
      ),
    );
  }

  // ─── Now Playing card ────────────────────────────────────────────────────

  Widget _buildTrackCard(SpotifyNowPlaying track) {
    final progress = track.durationMs != null && track.progressMs != null
        ? track.progressMs! / track.durationMs!
        : null;

    return GestureDetector(
      onTap: track.trackUrl != null
          ? () => PlatformShareService.openSpotify(track.trackUrl!)
          : null,
      child: Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(children: [
        Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(children: [
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: track.albumArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: track.albumArtUrl!,
                      width: 52.r, height: 52.r,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _AlbumArtPlaceholder(),
                    )
                  : _AlbumArtPlaceholder(),
            ),
            SizedBox(width: 12.w),
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _SpotifyIcon(size: 12),
                    SizedBox(width: 4.w),
                    Text(
                      track.isPlaying ? 'Now Playing' : 'Last Played',
                      style: TextStyles.font12regular
                          .copyWith(color: _green, fontSize: 10),
                    ),
                  ]),
                  SizedBox(height: 2.h),
                  Text(
                    track.trackName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.font14Medium
                        .copyWith(color: Colors.white),
                  ),
                  Text(
                    track.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.font12regular
                        .copyWith(color: const Color(0xFFAAAAAA)),
                  ),
                ],
              ),
            ),
            // Share button
            if (track.trackUrl != null)
              IconButton(
                icon: const Icon(Icons.share_rounded,
                    color: _green, size: 18),
                onPressed: () => PlatformShareService.shareSpotifyLink(
                  track.trackUrl!,
                  title: '${track.trackName} – ${track.artistName}',
                ),
                padding: EdgeInsets.zero,
                constraints:
                    BoxConstraints(minWidth: 32.r, minHeight: 32.r),
              ),
          ]),
        ),
        // Progress bar
        if (progress != null)
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(14.r),
              bottomRight: Radius.circular(14.r),
            ),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF282828),
              valueColor: const AlwaysStoppedAnimation(_green),
              minHeight: 3,
            ),
          ),
        if (widget.isOwnProfile)
          TextButton(
            onPressed: _disconnect,
            child: Text(
              'Disconnect Spotify',
              style: TextStyles.font12regular
                  .copyWith(color: Colors.white38, fontSize: 11),
            ),
          ),
      ]),
    ));
  }
}

// ─── Real Spotify icon (official SVG from Spotify's CDN) ──────────────────

class _SpotifyIcon extends StatelessWidget {
  final double size;
  const _SpotifyIcon({required this.size});

  // Spotify's official icon SVG (green circle + three white sound-wave arcs).
  // Source: https://developer.spotify.com/documentation/design#using-our-logo
  static const _svgUrl =
      'https://upload.wikimedia.org/wikipedia/commons/8/84/Spotify_icon.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.network(
      _svgUrl,
      width: size,
      height: size,
      placeholderBuilder: (_) => SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1DB954),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─── Album art placeholder ─────────────────────────────────────────────────

class _AlbumArtPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52,
      color: const Color(0xFF282828),
      child: Center(child: _SpotifyIcon(size: 28)),
    );
  }
}
