import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_actions.dart';

import '../../../../../../helpers/pump_app.dart';

/// See post_actions_test.md for what this covers and why.
void main() {
  late int likes;
  late int likeCounts;
  late int comments;
  late int shares;

  setUp(() {
    likes = 0;
    likeCounts = 0;
    comments = 0;
    shares = 0;
  });

  Future<void> pumpActions(
    WidgetTester tester, {
    int likeCount = 12,
    bool isLiked = false,
    VoidCallback? onLikeCountTap,
    bool wireCountTap = true,
  }) =>
      pumpApp(
        tester,
        Scaffold(
          body: Center(
            child: PostActions(
              isLiked: isLiked,
              likeCount: likeCount,
              commentCount: 3,
              shareCount: 1,
              viewsCount: 99,
              onLikeTap: () => likes++,
              onCommentTap: () => comments++,
              onShareTap: () => shares++,
              onLikeCountTap: wireCountTap ? () => likeCounts++ : null,
            ),
          ),
        ),
      );

  // The heart and the number sit side by side and used to be one button, so
  // there was no way to see who liked a post without also liking it yourself.
  group('the like count is its own tap target', () {
    testWidgets('tapping the count opens the likers list, not a like',
        (tester) async {
      await pumpActions(tester);

      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();

      expect(likeCounts, 1);
      expect(likes, 0, reason: 'looking at the likes must not add one');
    });

    testWidgets('tapping the heart still likes, and does not open the list',
        (tester) async {
      await pumpActions(tester);

      // The heart is the first SVG in the row.
      await tester.tap(find.byType(SvgPicture).first);
      await tester.pumpAndSettle();

      expect(likes, 1);
      expect(likeCounts, 0);
    });

    // Nothing to show, so the number shouldn't behave like a link.
    testWidgets('the count is inert when the post has no likes',
        (tester) async {
      await pumpActions(tester, likeCount: 0);

      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();

      expect(likeCounts, 0);
      expect(likes, 1,
          reason: 'with no separate target the whole button toggles the like');
    });

    // Other posts' actions (and any caller that hasn't opted in) must keep the
    // original single-button behaviour.
    testWidgets('without a count handler the whole button toggles the like',
        (tester) async {
      await pumpActions(tester, wireCountTap: false);

      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();

      expect(likes, 1);
      expect(likeCounts, 0);
    });
  });

  group('the other actions are untouched', () {
    testWidgets('comment and share still fire', (tester) async {
      await pumpActions(tester);

      await tester.tap(find.text('3'));
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(comments, 1);
      expect(shares, 1);
    });

    testWidgets('the view count is not interactive', (tester) async {
      await pumpActions(tester);

      await tester.tap(find.text('99'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(likes, 0);
      expect(likeCounts, 0);
      expect(comments, 0);
      expect(shares, 0);
    });
  });
}
