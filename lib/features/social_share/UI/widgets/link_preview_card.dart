import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/social_share/data/models/link_preview.dart';
import 'package:riff/features/social_share/data/repos/link_preview_repo.dart';
import 'package:riff/features/social_share/services/platform_share_service.dart';

/// Shows a rich link preview card for Spotify / TikTok / Instagram URLs
/// found inside a chat message or post. Fetches data lazily & caches it.
class LinkPreviewCard extends StatefulWidget {
  final String url;
  final bool compact; // compact = inside a chat bubble; expanded = in post
  const LinkPreviewCard({super.key, required this.url, this.compact = true});

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  LinkPreview? _preview;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preview = await getIt<LinkPreviewRepo>().fetchPreview(widget.url);
    if (mounted) setState(() { _preview = preview; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _Skeleton(compact: widget.compact);
    final p = _preview;
    if (p == null) return const SizedBox.shrink();

    switch (p.platform) {
      case 'spotify':
        return _SpotifyCard(preview: p, compact: widget.compact);
      case 'tiktok':
        return _TikTokCard(preview: p, compact: widget.compact);
      case 'instagram':
        return _InstagramCard(preview: p, compact: widget.compact);
      default:
        return _GenericCard(preview: p, compact: widget.compact);
    }
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  final bool compact;
  const _Skeleton({required this.compact});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final h = compact ? 56.h : 80.h;
    return Container(
      height: h,
      margin: EdgeInsets.only(top: 6.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }
}

// ─── Spotify card (green) ─────────────────────────────────────────────────────

class _SpotifyCard extends StatelessWidget {
  final LinkPreview preview;
  final bool compact;
  const _SpotifyCard({required this.preview, required this.compact});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => PlatformShareService.openUrl(preview.url),
      child: Container(
        margin: EdgeInsets.only(top: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(12.r),
        ),
        clipBehavior: Clip.hardEdge,
        child: compact ? _SpotifyCompact(preview: preview) : _SpotifyFull(preview: preview),
      ),
    );
  }
}

class _SpotifyCompact extends StatelessWidget {
  final LinkPreview preview;
  const _SpotifyCompact({required this.preview});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (preview.image != null)
        CachedNetworkImage(
          imageUrl: preview.image!,
          width: 56.r, height: 56.r,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _SpotifyIconBox(),
        )
      else
        _SpotifyIconBox(),
      SizedBox(width: 10.w),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(preview.title ?? 'Spotify', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyles.font12semiBold.copyWith(color: Colors.white)),
          if (preview.authorName != null)
            Text(preview.authorName!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyles.font12regular.copyWith(color: const Color(0xFFAAAAAA))),
        ]),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF1DB954)),
      ),
    ]);
  }
}

class _SpotifyFull extends StatelessWidget {
  final LinkPreview preview;
  const _SpotifyFull({required this.preview});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (preview.image != null)
        CachedNetworkImage(
          imageUrl: preview.image!,
          width: double.infinity, height: 140.h,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => SizedBox(height: 140.h, child: Center(child: _SpotifyIconBox())),
        ),
      Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.music_note, size: 14, color: Color(0xFF1DB954)),
              SizedBox(width: 4.w),
              Text('Spotify', style: TextStyles.font12regular.copyWith(color: const Color(0xFF1DB954))),
            ]),
            SizedBox(height: 2.h),
            Text(preview.title ?? 'Listen on Spotify', maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyles.font14Medium.copyWith(color: Colors.white)),
          ])),
          SizedBox(width: 8.w),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            ),
            onPressed: () => PlatformShareService.openUrl(preview.url),
            child: Text('Play', style: TextStyles.font12semiBold.copyWith(color: Colors.black)),
          ),
        ]),
      ),
    ]);
  }
}

class _SpotifyIconBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56.r, height: 56.r,
      color: const Color(0xFF282828),
      child: const Icon(Icons.music_note, color: Color(0xFF1DB954), size: 28),
    );
  }
}

// ─── TikTok card (black / white) ─────────────────────────────────────────────

class _TikTokCard extends StatelessWidget {
  final LinkPreview preview;
  final bool compact;
  const _TikTokCard({required this.preview, required this.compact});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => PlatformShareService.openUrl(preview.url),
      child: Container(
        margin: EdgeInsets.only(top: 6.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF010101),
          borderRadius: BorderRadius.circular(12.r),
        ),
        clipBehavior: Clip.hardEdge,
        child: compact ? _TikTokCompact(preview: preview) : _TikTokFull(preview: preview),
      ),
    );
  }
}

class _TikTokCompact extends StatelessWidget {
  final LinkPreview preview;
  const _TikTokCompact({required this.preview});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (preview.image != null)
        CachedNetworkImage(
          imageUrl: preview.image!,
          width: 56.r, height: 56.r,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _TikTokIconBox(),
        )
      else
        _TikTokIconBox(),
      SizedBox(width: 10.w),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          if (preview.authorName != null)
            Text('@${preview.authorName}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyles.font12semiBold.copyWith(color: Colors.white)),
          Text(preview.title ?? 'TikTok Video', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyles.font12regular.copyWith(color: const Color(0xFFAAAAAA))),
        ]),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white),
      ),
    ]);
  }
}

class _TikTokFull extends StatelessWidget {
  final LinkPreview preview;
  const _TikTokFull({required this.preview});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      if (preview.image != null)
        CachedNetworkImage(
          imageUrl: preview.image!,
          width: double.infinity, height: 200.h,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => SizedBox(height: 200.h, child: Center(child: _TikTokIconBox())),
        )
      else
        SizedBox(height: 200.h, child: Center(child: _TikTokIconBox())),
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xCC000000)],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 10.h, left: 12.w, right: 12.w,
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (preview.authorName != null)
              Text('@${preview.authorName}',
                  style: TextStyles.font12semiBold.copyWith(color: Colors.white)),
            Text(preview.title ?? 'Watch on TikTok', maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyles.font12regular.copyWith(color: const Color(0xDDFFFFFF))),
          ])),
          SizedBox(width: 8.w),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0050),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            ),
            onPressed: () => PlatformShareService.openUrl(preview.url),
            child: Text('Watch', style: TextStyles.font12semiBold.copyWith(color: Colors.white)),
          ),
        ]),
      ),
    ]);
  }
}

class _TikTokIconBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56.r, height: 56.r,
      color: Colors.black,
      child: const Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 28),
    );
  }
}

// ─── Instagram card (gradient) ────────────────────────────────────────────────

class _InstagramCard extends StatelessWidget {
  final LinkPreview preview;
  final bool compact;
  const _InstagramCard({required this.preview, required this.compact});

  static const _gradient = LinearGradient(
    colors: [Color(0xFF405DE6), Color(0xFF833AB4), Color(0xFFC13584), Color(0xFFE1306C), Color(0xFFFD1D1D), Color(0xFFF77737)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => PlatformShareService.openUrl(preview.url),
      child: Container(
        margin: EdgeInsets.only(top: 6.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12.r),
        ),
        clipBehavior: Clip.hardEdge,
        child: compact ? _InstagramCompact(preview: preview, gradient: _gradient)
            : _InstagramFull(preview: preview, gradient: _gradient, isDark: isDark),
      ),
    );
  }
}

class _InstagramCompact extends StatelessWidget {
  final LinkPreview preview;
  final Gradient gradient;
  const _InstagramCompact({required this.preview, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 56.r, height: 56.r,
        child: preview.image != null
            ? CachedNetworkImage(imageUrl: preview.image!, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _IgIcon(gradient: gradient, size: 56))
            : _IgIcon(gradient: gradient, size: 56),
      ),
      SizedBox(width: 10.w),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(children: [
            ShaderMask(
              shaderCallback: (b) => gradient.createShader(b),
              child: const Icon(Icons.camera_alt_outlined, size: 12, color: Colors.white),
            ),
            SizedBox(width: 4.w),
            Text('Instagram', style: TextStyles.font12semiBold.copyWith(
                foreground: Paint()..shader = gradient.createShader(const Rect.fromLTWH(0, 0, 80, 14)))),
          ]),
          Text(preview.title ?? (preview.type == 'reel' ? 'Instagram Reel' : 'Instagram Post'),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyles.font12regular.copyWith(color: ColorManager.normalGrey)),
        ]),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: const Icon(Icons.open_in_new_rounded, size: 16, color: ColorManager.normalGrey),
      ),
    ]);
  }
}

class _InstagramFull extends StatelessWidget {
  final LinkPreview preview;
  final Gradient gradient;
  final bool isDark;
  const _InstagramFull({required this.preview, required this.gradient, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (preview.image != null)
        CachedNetworkImage(imageUrl: preview.image!, width: double.infinity, height: 180.h, fit: BoxFit.cover,
            errorWidget: (_, __, ___) => SizedBox(height: 180.h, child: Center(child: _IgIcon(gradient: gradient, size: 56))))
      else
        Container(height: 100.h, decoration: BoxDecoration(gradient: gradient as LinearGradient),
            child: const Center(child: Icon(Icons.camera_alt_outlined, size: 40, color: Colors.white))),
      Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.camera_alt_outlined, size: 13),
              SizedBox(width: 4.w),
              Text('Instagram', style: TextStyles.font12semiBold),
            ]),
            if (preview.title != null)
              Text(preview.title!, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyles.font12regular.copyWith(color: ColorManager.normalGrey)),
          ])),
          SizedBox(width: 8.w),
          Container(
            decoration: BoxDecoration(gradient: gradient as LinearGradient, borderRadius: BorderRadius.circular(20.r)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              ),
              onPressed: () => PlatformShareService.openUrl(preview.url),
              child: Text('Open', style: TextStyles.font12semiBold.copyWith(color: Colors.white)),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _IgIcon extends StatelessWidget {
  final Gradient gradient;
  final double size;
  const _IgIcon({required this.gradient, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.r, height: size.r,
      decoration: BoxDecoration(gradient: gradient as LinearGradient),
      child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: size * 0.45),
    );
  }
}

// ─── Generic OG card ─────────────────────────────────────────────────────────

class _GenericCard extends StatelessWidget {
  final LinkPreview preview;
  final bool compact;
  const _GenericCard({required this.preview, required this.compact});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => PlatformShareService.openUrl(preview.url),
      child: Container(
        margin: EdgeInsets.only(top: 6.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(children: [
          if (preview.image != null)
            CachedNetworkImage(imageUrl: preview.image!, width: 64.r, height: 64.r, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => SizedBox(width: 64.r, height: 64.r,
                    child: Icon(Icons.link_rounded, color: ColorManager.normalGrey))),
          SizedBox(width: 10.w),
          Expanded(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: preview.image == null ? 10.w : 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              if (preview.title != null)
                Text(preview.title!, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyles.font12semiBold),
              if (preview.description != null)
                Text(preview.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyles.font12regular.copyWith(color: ColorManager.normalGrey)),
              Text(Uri.tryParse(preview.url)?.host ?? preview.url,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyles.font12regular.copyWith(color: ColorManager.accent, fontSize: 10)),
            ]),
          )),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Icon(Icons.open_in_new_rounded, size: 16, color: ColorManager.normalGrey),
          ),
        ]),
      ),
    );
  }
}
