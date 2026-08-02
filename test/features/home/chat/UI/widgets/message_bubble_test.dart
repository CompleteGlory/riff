import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/home/chat/UI/widgets/message_bubble.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/fullscsreen_image.dart';
import 'package:riff/generated/l10n.dart';

/// See message_bubble_test.md for what this covers and why.
void main() {
  ChatMessage image({
    String? url = 'https://cdn.example/pic.jpg',
    String? localPath,
    MessageDelivery delivery = MessageDelivery.complete,
  }) =>
      ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        type: MessageType.image,
        mediaUrl: url,
        localMediaPath: localPath,
        isDeleted: false,
        createdAt: DateTime(2026, 8, 2, 12),
        sender: const MessageSender(id: 'u1'),
        clientId: delivery == MessageDelivery.complete ? null : 'local-1',
        delivery: delivery,
      );

  /// Pumps a bubble.
  ///
  /// Deliberately not `pump_app.dart`'s helper: that ends in `pumpAndSettle`,
  /// and a *pending* bubble carries a `CircularProgressIndicator` that never
  /// settles. This takes a bounded pump instead.
  Future<void> pumpBubble(
    WidgetTester tester,
    ChatMessage message, {
    VoidCallback? onRetry,
  }) async {
    // An image bubble is 0.65.sw wide and unbounded in height. On the default
    // 800x600 test surface it overflows and its centre lands off-screen, so
    // `tap()` misses the widget it just found. Give it a phone-shaped viewport.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(
            body: MessageBubble(message: message, isMe: true, onRetry: onRetry),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Advances far enough for a route transition to finish, without waiting on
  /// animations that never stop.
  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('tapping an image', () {
    testWidgets('opens the same fullscreen viewer posts use', (tester) async {
      await pumpBubble(tester, image());

      await tester.tap(find.byType(Image));
      await settleRoute(tester);

      expect(find.byType(FullScreenImage), findsOneWidget);
      final viewer =
          tester.widget<FullScreenImage>(find.byType(FullScreenImage));
      expect(viewer.isLocalFile, isFalse);
      expect(viewer.images, ['https://cdn.example/pic.jpg']);
    });

    // An image still uploading has no remote URL yet. Making the user wait for
    // the upload before they can open it would undo the point of the optimistic
    // bubble.
    //
    // The callback is invoked directly rather than through `tester.tap`:
    // `Image.file` never resolves under the test binding's fake clock, so the
    // bubble lays out zero-height and a real tap would miss the widget it just
    // found. The keyed GestureDetector is exactly the thing under test.
    testWidgets('opens a still-uploading image straight off disk',
        (tester) async {
      await pumpBubble(
        tester,
        image(
          url: null,
          localPath: '/tmp/pic.jpg',
          delivery: MessageDelivery.pending,
        ),
      );

      tester
          .widget<GestureDetector>(find.byKey(MessageBubble.imageTapKey))
          .onTap!();
      await settleRoute(tester);

      final viewer =
          tester.widget<FullScreenImage>(find.byType(FullScreenImage));
      expect(viewer.isLocalFile, isTrue);
      expect(viewer.images, ['/tmp/pic.jpg']);
    });

    // The whole bubble is the retry target once a send has failed. Opening the
    // viewer would swallow that tap and leave no way to resend.
    testWidgets('a failed image retries instead of opening the viewer',
        (tester) async {
      var retried = false;
      await pumpBubble(
        tester,
        image(delivery: MessageDelivery.failed),
        onRetry: () => retried = true,
      );

      expect(
        tester
            .widget<GestureDetector>(find.byKey(MessageBubble.imageTapKey))
            .onTap,
        isNull,
        reason: 'the image must not absorb the tap while the send has failed',
      );

      await tester.tap(find.byType(Image));
      await settleRoute(tester);

      expect(retried, isTrue);
      expect(find.byType(FullScreenImage), findsNothing);
    });
  });

  group('the viewer', () {
    testWidgets('closes back to the chat', (tester) async {
      await pumpBubble(tester, image());
      await tester.tap(find.byType(Image));
      await settleRoute(tester);

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      // A complete bubble has no spinner, so this one can settle properly.
      await tester.pumpAndSettle();

      expect(find.byType(FullScreenImage), findsNothing);
      expect(find.byType(MessageBubble), findsOneWidget);
    });

    // The page dots and the "1 / 3" counter are gallery affordances. A chat
    // message carries exactly one image, so neither belongs.
    testWidgets('shows no gallery chrome for a single image', (tester) async {
      await pumpBubble(tester, image());
      await tester.tap(find.byType(Image));
      await settleRoute(tester);

      expect(find.textContaining('/'), findsNothing);
    });
  });
}
