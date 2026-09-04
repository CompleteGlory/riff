import 'dart:io';

/// What the in-app camera hands back to whoever opened it.
///
/// A plain value object rather than a bare `File` because every caller needs
/// to know *which kind* of media came back: a post appends it to a list that
/// renders photos and videos differently, and chat has to pick a MIME type
/// before uploading. Sniffing the file extension at each call site is how that
/// knowledge gets duplicated and then drifts.
class CameraCapture {
  const CameraCapture({required this.file, required this.isVideo});

  final File file;
  final bool isVideo;

  /// The MIME type to send with an upload.
  ///
  /// The camera plugin writes JPEG stills and MP4 video on both platforms, so
  /// this is a fact about what we just recorded, not a guess about an arbitrary
  /// file the user chose.
  String get mimeType => isVideo ? 'video/mp4' : 'image/jpeg';

  /// A filename for the upload. The path's basename is a plugin-generated
  /// timestamp, which is unique and harmless to expose.
  String get name => file.path.split(Platform.pathSeparator).last;
}

/// Which kind of capture the shutter performs on a plain tap.
///
/// Exists so video is reachable **by tapping**, not only by holding the
/// shutter down. A press-and-hold is a dragging-style interaction, and an
/// interface that offers no alternative to it excludes anyone who cannot hold
/// a steady press — the same reason a drag-only control needs a button beside
/// it.
enum CameraMode { photo, video }
