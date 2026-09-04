import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/camera/media_source_sheet.dart';
import 'package:riff/generated/l10n.dart';

import '../../helpers/pump_app.dart';

/// See media_source_sheet_test.md for what this covers and why.
void main() {
  /// Pumps a button that opens the sheet, and records what it returns.
  Future<MediaSource?> openAndTap(
    WidgetTester tester, {
    required bool allowVideo,
    required String tapLabel,
  }) async {
    MediaSource? result;
    late BuildContext ctx;

    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          ctx = context;
          return const Scaffold(body: SizedBox.shrink());
        },
      ),
    );

    final future = MediaSourceSheet.show(ctx, allowVideo: allowVideo)
        .then((value) => result = value);
    await tester.pumpAndSettle();

    if (tapLabel.isNotEmpty) {
      await tester.tap(find.text(tapLabel));
      await tester.pumpAndSettle();
      await future;
    }
    return result;
  }

  testWidgets('offers camera first, then the two library options', (
    tester,
  ) async {
    await openAndTap(tester, allowVideo: true, tapLabel: '');
    final s = S.current;

    // Camera leads because it is the option that was missing: the point of
    // the sheet is that capturing is now as reachable as browsing.
    final camera = tester.getTopLeft(find.text(s.takePhotoOrVideo)).dy;
    final photos = tester.getTopLeft(find.text(s.chooseFromGallery)).dy;
    final videos = tester.getTopLeft(find.text(s.chooseVideo)).dy;

    expect(camera, lessThan(photos));
    expect(photos, lessThan(videos));
  });

  testWidgets('returns the camera choice', (tester) async {
    final result = await openAndTap(
      tester,
      allowVideo: true,
      tapLabel: S.current.takePhotoOrVideo,
    );
    expect(result, MediaSource.camera);
  });

  testWidgets('returns the gallery choice', (tester) async {
    final result = await openAndTap(
      tester,
      allowVideo: true,
      tapLabel: S.current.chooseFromGallery,
    );
    expect(result, MediaSource.photoLibrary);
  });

  testWidgets('returns the video choice', (tester) async {
    final result = await openAndTap(
      tester,
      allowVideo: true,
      tapLabel: S.current.chooseVideo,
    );
    expect(result, MediaSource.videoLibrary);
  });

  testWidgets('hides video entirely where only a still is accepted', (
    tester,
  ) async {
    await openAndTap(tester, allowVideo: false, tapLabel: '');

    // A group photo cannot be a video, so the option is absent rather than
    // offered and then rejected — and the camera row promises only a photo.
    expect(find.text(S.current.chooseVideo), findsNothing);
    expect(find.text(S.current.takePhotoOrVideo), findsNothing);
    expect(find.text(S.current.takePhoto), findsOneWidget);
  });

  testWidgets('every row clears the minimum touch target', (tester) async {
    await openAndTap(tester, allowVideo: true, tapLabel: '');

    for (final label in [
      S.current.takePhotoOrVideo,
      S.current.chooseFromGallery,
      S.current.chooseVideo,
    ]) {
      final tile = find.ancestor(
        of: find.text(label),
        matching: find.byType(ListTile),
      );
      // 48dp is the Android floor; iOS asks for 44pt. One number satisfies
      // both, and these rows are taller still.
      expect(tester.getSize(tile).height, greaterThanOrEqualTo(48.0),
          reason: '"$label" row is too short to tap reliably');
    }
  });

  testWidgets('dismissing without choosing returns null', (tester) async {
    MediaSource? result;
    late BuildContext ctx;
    var completed = false;

    await pumpApp(
      tester,
      Builder(builder: (context) {
        ctx = context;
        return const Scaffold(body: SizedBox.shrink());
      }),
    );

    unawaited(MediaSourceSheet.show(ctx).then((v) {
      result = v;
      completed = true;
    }));
    await tester.pumpAndSettle();

    Navigator.of(ctx).pop();
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
  });
}

void unawaited(Future<void> future) {}
