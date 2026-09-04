import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:riff/core/camera/device_gallery.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/generated/l10n.dart';

/// The strip of recent photos that sits inside the camera, above the shutter.
///
/// There is no chooser before the camera any more: opening the camera *is*
/// opening the picker, and this is the half of it that shows what is already
/// on the phone. Tapping a thumbnail returns it; "All" opens the full grid.
class GalleryStrip extends StatefulWidget {
  const GalleryStrip({
    super.key,
    required this.allowVideo,
    required this.onPicked,
    required this.onExpand,
  });

  final bool allowVideo;
  final ValueChanged<AssetEntity> onPicked;
  final VoidCallback onExpand;

  @override
  State<GalleryStrip> createState() => _GalleryStripState();
}

class _GalleryStripState extends State<GalleryStrip> {
  final _gallery = DeviceGallery(pageSize: 24);
  List<AssetEntity> _assets = const [];
  GalleryAccess _access = GalleryAccess.denied;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final access = await DeviceGallery.requestAccess();
    if (!mounted) return;
    if (access == GalleryAccess.denied) {
      setState(() {
        _access = access;
        _loading = false;
      });
      return;
    }
    final assets = await _gallery.load(page: 0, allowVideo: widget.allowVideo);
    if (!mounted) return;
    setState(() {
      _access = access;
      _assets = assets;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // A fixed height whatever the state, so the shutter never moves as the
    // library finishes loading. Controls that shift under a thumb are how a
    // tap lands on the wrong thing.
    return SizedBox(
      height: 84.h,
      child: _loading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ColorManager.white,
                ),
              ),
            )
          : _access == GalleryAccess.denied
              ? _DeniedNotice(onRetry: _load)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _assets.length + 1,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return _AllTile(onTap: widget.onExpand);
                    }
                    final asset = _assets[i - 1];
                    return GalleryThumb(
                      asset: asset,
                      edge: 72.w,
                      onTap: () => widget.onPicked(asset),
                    );
                  },
                ),
    );
  }
}

/// The leading tile that opens the full grid.
class _AllTile extends StatelessWidget {
  const _AllTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: S.of(context).allPhotos,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 72.w,
          height: 72.w,
          decoration: BoxDecoration(
            color: const Color(0x59000000),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0x40FFFFFF)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_rounded,
                  size: 22.r, color: ColorManager.white),
              SizedBox(height: 4.h),
              Text(
                S.of(context).allPhotos,
                style: TextStyles.font12regular
                    .copyWith(color: ColorManager.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeniedNotice extends StatelessWidget {
  const _DeniedNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onRetry,
        child: Text(
          S.of(context).galleryPermissionNeeded,
          style: TextStyles.font12regular.copyWith(color: ColorManager.white),
        ),
      ),
    );
  }
}

/// One gallery cell: the thumbnail, a video badge, and an optional selection
/// number for multi-select.
class GalleryThumb extends StatelessWidget {
  const GalleryThumb({
    super.key,
    required this.asset,
    required this.edge,
    required this.onTap,
    this.selectionIndex,
  });

  final AssetEntity asset;
  final double edge;
  final VoidCallback onTap;

  /// 1-based position in the current selection, or null when unselected.
  final int? selectionIndex;

  @override
  Widget build(BuildContext context) {
    final isVideo = asset.type == AssetType.video;
    final selected = selectionIndex != null;

    return Semantics(
      button: true,
      selected: selected,
      label: isVideo
          ? S.of(context).galleryVideoItem(_duration(asset.duration))
          : S.of(context).galleryPhotoItem,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: SizedBox(
                width: edge,
                height: edge,
                child: FutureBuilder<dynamic>(
                  future: DeviceGallery.thumbnail(asset, 200),
                  builder: (context, snapshot) {
                    final bytes = snapshot.data;
                    if (bytes == null) {
                      return Container(color: const Color(0x33FFFFFF));
                    }
                    return Image.memory(bytes, fit: BoxFit.cover);
                  },
                ),
              ),
            ),
            if (isVideo)
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xB3000000),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    _duration(asset.duration),
                    style: TextStyles.font12regular
                        .copyWith(color: ColorManager.white),
                  ),
                ),
              ),
            if (selected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x66000000),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: ColorManager.accent, width: 2),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        width: 22.r,
                        height: 22.r,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: ColorManager.accent,
                          shape: BoxShape.circle,
                        ),
                        // A number, not just a tint: colour alone must not be
                        // the only thing carrying "selected", and for a
                        // multi-pick the order matters too.
                        child: Text(
                          '$selectionIndex',
                          style: TextStyles.font12Medium
                              .copyWith(color: ColorManager.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _duration(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// The full-library grid, shown when the strip's "All" tile is tapped.
///
/// Returns the chosen assets, or null when dismissed. With [maxSelection] of 1
/// a tap returns immediately; above that, taps accumulate and a confirm button
/// appears — a post takes up to ten images and asking for them one at a time
/// would be worse than the picker this replaced.
class GalleryGridSheet extends StatefulWidget {
  const GalleryGridSheet({
    super.key,
    required this.allowVideo,
    required this.maxSelection,
  });

  final bool allowVideo;
  final int maxSelection;

  static Future<List<AssetEntity>?> show(
    BuildContext context, {
    required bool allowVideo,
    required int maxSelection,
  }) {
    return showModalBottomSheet<List<AssetEntity>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorManager.blackDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => GalleryGridSheet(
        allowVideo: allowVideo,
        maxSelection: maxSelection,
      ),
    );
  }

  @override
  State<GalleryGridSheet> createState() => _GalleryGridSheetState();
}

class _GalleryGridSheetState extends State<GalleryGridSheet> {
  final _gallery = DeviceGallery();
  final _scroll = ScrollController();
  final List<AssetEntity> _assets = [];
  final List<AssetEntity> _selected = [];

  int _page = 0;
  bool _loading = true;
  bool _exhausted = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loading || _exhausted) return;
    // Fetch the next page before the user reaches the end, so scrolling does
    // not stall on a library of thousands.
    if (_scroll.position.pixels >
        _scroll.position.maxScrollExtent - 600) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    final page = await _gallery.load(page: _page, allowVideo: widget.allowVideo);
    if (!mounted) return;
    setState(() {
      _assets.addAll(page);
      _exhausted = page.isEmpty;
      _page++;
      _loading = false;
    });
  }

  void _toggle(AssetEntity asset) {
    if (widget.maxSelection <= 1) {
      Navigator.pop(context, [asset]);
      return;
    }
    setState(() {
      if (_selected.contains(asset)) {
        _selected.remove(asset);
      } else if (_selected.length < widget.maxSelection) {
        _selected.add(asset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final multi = widget.maxSelection > 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, sheetScroll) => Column(
        children: [
          SizedBox(height: 12.h),
          ExcludeSemantics(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: ColorManager.darkGrey,
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 8.h),
            child: Row(
              children: [
                Text(
                  S.of(context).allPhotos,
                  style: TextStyles.font16Medium
                      .copyWith(color: ColorManager.white),
                ),
                const Spacer(),
                if (multi && _selected.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: TextButton.styleFrom(
                      backgroundColor: ColorManager.accent,
                      minimumSize: Size(88.w, 44.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                    ),
                    child: Text(
                      S.of(context).addSelected(_selected.length),
                      style: TextStyles.font14Medium
                          .copyWith(color: ColorManager.black),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              controller: sheetScroll,
              padding: EdgeInsets.all(8.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4.w,
                crossAxisSpacing: 4.w,
              ),
              itemCount: _assets.length,
              itemBuilder: (context, i) {
                final asset = _assets[i];
                final index = _selected.indexOf(asset);
                return GalleryThumb(
                  asset: asset,
                  edge: 120.w,
                  selectionIndex:
                      multi && index >= 0 ? index + 1 : null,
                  onTap: () => _toggle(asset),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
