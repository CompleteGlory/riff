import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/camera/device_gallery.dart';

/// See device_gallery_test.md for what this covers and why.
void main() {
  group('GalleryAccess', () {
    test('treats limited access as its own state, not a denial', () {
      // iOS lets someone share only a few photos. Folding that into "denied"
      // would blank the strip for a user who did grant access — and hide the
      // one affordance that lets them widen the selection.
      expect(GalleryAccess.values, [
        GalleryAccess.full,
        GalleryAccess.limited,
        GalleryAccess.denied,
      ]);
    });
  });

  group('DeviceGallery', () {
    test('pages rather than reading the whole library', () {
      // A phone library runs to tens of thousands of items. Reading them all
      // to fill a strip of eight would stall the camera opening, which is the
      // one moment the user is waiting on.
      expect(DeviceGallery().pageSize, 60);
      expect(DeviceGallery(pageSize: 24).pageSize, 24);
    });
  });
}
