import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import 'package:riff/core/camera/camera_capture.dart';

/// Reads the device's photo library for the strip and grid inside the camera.
///
/// Wrapped rather than called directly from widgets for the usual reason: it
/// is the one part of the gallery that talks to the platform, so keeping it
/// behind a small surface leaves the widgets testable and gives the permission
/// rules a single home.
class DeviceGallery {
  DeviceGallery({this.pageSize = 60});

  /// How many assets are fetched at a time. A phone library runs to tens of
  /// thousands of items; reading them all to show a strip of eight would stall
  /// the camera opening.
  final int pageSize;

  AssetPathEntity? _album;

  /// Whether the user has granted enough access to read anything.
  ///
  /// iOS "limited" access counts: the user picked some photos to share, and
  /// those are exactly what we may show. Treating it as a denial would leave
  /// the strip empty with no explanation.
  static Future<GalleryAccess> requestAccess() async {
    final state = await PhotoManager.requestPermissionExtend();
    return switch (state) {
      PermissionState.authorized => GalleryAccess.full,
      PermissionState.limited => GalleryAccess.limited,
      _ => GalleryAccess.denied,
    };
  }

  /// Opens the OS picker that lets an iOS user widen a limited selection.
  static Future<void> presentLimitedSelection() =>
      PhotoManager.presentLimited();

  /// Loads one page of the most recent items, newest first.
  ///
  /// [allowVideo] false filters to images only, so a surface that cannot
  /// accept a clip never shows one that it would then have to refuse.
  Future<List<AssetEntity>> load({
    required int page,
    required bool allowVideo,
  }) async {
    _album ??= await _resolveAlbum(allowVideo: allowVideo);
    final album = _album;
    if (album == null) return const [];
    return album.getAssetListPaged(page: page, size: pageSize);
  }

  Future<AssetPathEntity?> _resolveAlbum({required bool allowVideo}) async {
    final albums = await PhotoManager.getAssetPathList(
      // `isAll` gives the combined "Recents"/"All" album rather than a
      // user-created one, which is what a recents strip should show.
      onlyAll: true,
      type: allowVideo ? RequestType.common : RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
    return albums.isEmpty ? null : albums.first;
  }

  /// Thumbnail bytes for a grid cell. Null when the asset cannot be decoded —
  /// an iCloud item not yet downloaded, or a file the OS has since removed.
  static Future<Uint8List?> thumbnail(AssetEntity asset, int edge) =>
      asset.thumbnailDataWithSize(ThumbnailSize.square(edge));

  /// Resolves an asset to a real file on disk, downloading from iCloud if it
  /// has to. Null when that fails, which is why callers must not assume a
  /// selection always yields a file.
  static Future<CameraCapture?> materialize(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return null;
    return CameraCapture(
      file: file,
      isVideo: asset.type == AssetType.video,
    );
  }
}

/// How much of the library the user has agreed to share.
enum GalleryAccess { full, limited, denied }
