import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/camera/camera_capture.dart';

/// See camera_capture_test.md for what this covers and why.
void main() {
  group('CameraCapture', () {
    test('describes a still as a JPEG', () {
      final shot = CameraCapture(file: File('/tmp/CAP1234.jpg'), isVideo: false);

      expect(shot.isVideo, isFalse);
      expect(shot.mimeType, 'image/jpeg');
    });

    test('describes a recording as MP4', () {
      final clip = CameraCapture(file: File('/tmp/REC1234.mp4'), isVideo: true);

      expect(clip.isVideo, isTrue);
      expect(clip.mimeType, 'video/mp4');
    });

    test('takes the MIME type from what was captured, not the extension', () {
      // The camera plugin decides the container; the path is incidental. A
      // call site that sniffed the extension instead would mislabel anything
      // written with an unexpected suffix, and the API branches on this.
      final clip = CameraCapture(file: File('/tmp/no-extension'), isVideo: true);

      expect(clip.mimeType, 'video/mp4');
    });

    test('names the upload after the file, without its directory', () {
      final path = '${Platform.pathSeparator}tmp'
          '${Platform.pathSeparator}riff'
          '${Platform.pathSeparator}CAP987.jpg';

      expect(CameraCapture(file: File(path), isVideo: false).name, 'CAP987.jpg');
    });
  });

  group('CameraMode', () {
    test('offers photo and video as explicit, tappable choices', () {
      // The mode switch is what makes recording reachable without holding the
      // shutter down. Losing a case here would silently remove the only
      // press-free route to video.
      expect(CameraMode.values, [CameraMode.photo, CameraMode.video]);
    });
  });
}
