import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/home/chat/UI/widgets/message_bubble.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/generated/l10n.dart';

/// See message_reactions_test.md for what this covers and why.
void main() {
  ChatMessage text({
    String content = 'hello',
    DateTime? editedAt,
    List<MessageReaction> reactions = const [],
    bool isDeleted = false,
  }) =>
      ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        type: MessageType.text,
        content: content,
        isDeleted: isDeleted,
        createdAt: DateTime(2026, 8, 2, 12),
        sender: const MessageSender(id: 'u1'),
        editedAt: editedAt,
        reactions: reactions,
      );

  final tapped = <String>[];

  setUp(tapped.clear);

  Future<void> pumpBubble(
    WidgetTester tester,
    ChatMessage message, {
    String? myId = 'u1',
  }) async {
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
            body: MessageBubble(
              message: message,
              isMe: true,
              myId: myId,
              onReactionTap: tapped.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('reaction chips', () {
    testWidgets('nothing is drawn when there are no reactions',
        (tester) async {
      await pumpBubble(tester, text());

      expect(find.text('❤️'), findsNothing);
    });

    testWidgets('one chip per emoji', (tester) async {
      await pumpBubble(
        tester,
        text(reactions: const [
          MessageReaction(emoji: '❤️', userId: 'u2'),
          MessageReaction(emoji: '😂', userId: 'u3'),
        ]),
      );

      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('😂'), findsOneWidget);
    });

    // The same emoji from several people is one chip with a count, not one
    // chip each — a group chat would otherwise fill the screen with hearts.
    testWidgets('the same emoji collapses into a count', (tester) async {
      await pumpBubble(
        tester,
        text(reactions: const [
          MessageReaction(emoji: '❤️', userId: 'u2'),
          MessageReaction(emoji: '❤️', userId: 'u3'),
        ]),
      );

      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    // A single reaction needs no "1" beside it.
    testWidgets('a lone reaction shows no count', (tester) async {
      await pumpBubble(
        tester,
        text(reactions: const [MessageReaction(emoji: '❤️', userId: 'u2')]),
      );

      expect(find.text('1'), findsNothing);
    });

    testWidgets('tapping a chip reports the emoji', (tester) async {
      await pumpBubble(
        tester,
        text(reactions: const [MessageReaction(emoji: '❤️', userId: 'u2')]),
      );

      await tester.tap(find.text('❤️'));
      await tester.pump();

      expect(tapped, ['❤️']);
    });
  });

  group('edited marker', () {
    testWidgets('an unedited message carries no marker', (tester) async {
      await pumpBubble(tester, text());

      expect(find.text(S.current.messageEditedLabel), findsNothing);
    });

    // Presence of edited_at is the signal, not a comparison against
    // created_at — a message saved twice for unrelated reasons must not get
    // labelled as something the sender rewrote.
    testWidgets('an edited message is labelled', (tester) async {
      await pumpBubble(tester, text(editedAt: DateTime(2026, 8, 2, 13)));

      expect(find.text(S.current.messageEditedLabel), findsOneWidget);
    });

    // Deleted bubbles are a different widget entirely; the marker would be
    // talking about text nobody can see.
    testWidgets('a deleted message shows neither marker nor text',
        (tester) async {
      await pumpBubble(
        tester,
        text(isDeleted: true, editedAt: DateTime(2026, 8, 2, 13)),
      );

      expect(find.text(S.current.messageEditedLabel), findsNothing);
      expect(find.text('hello'), findsNothing);
      expect(find.text(S.current.messageDeletedLabel), findsOneWidget);
    });
  });
}
