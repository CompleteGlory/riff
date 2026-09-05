import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/widgets/linkified_text.dart';

/// See linkified_text_test.md for what this covers and why.
void main() {
  final tapped = <String>[];

  setUp(tapped.clear);

  Future<void> pump(WidgetTester tester, String text,
      {VoidCallback? onBackgroundTap}) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GestureDetector(
          // Stands in for the post card, which wraps the body and opens the
          // post on tap. The two recognizers share an arena.
          onTap: onBackgroundTap,
          child: LinkifiedText(
            text: text,
            style: const TextStyle(fontSize: 14),
            onLinkTap: (url) async => tapped.add(url),
          ),
        ),
      ),
    ));
  }

  /// Fires the recognizer attached to the span whose text is [linkText].
  void tapLink(WidgetTester tester, String linkText) {
    final widget = tester.widget<Text>(find.byType(Text));
    final span = widget.textSpan! as TextSpan;
    TextSpan? found;
    span.visitChildren((child) {
      if (child is TextSpan && child.text == linkText) found = child;
      return true;
    });
    expect(found, isNotNull, reason: 'no span for "$linkText"');
    (found!.recognizer! as TapGestureRecognizer).onTap!();
  }

  testWidgets('renders a plain Text when there are no links', (tester) async {
    await pump(tester, 'nothing to see');

    // The common case must not pay for the machinery: no spans, no
    // recognizers, just the widget that was there before.
    final widget = tester.widget<Text>(find.byType(Text));
    expect(widget.data, 'nothing to see');
    expect(widget.textSpan, isNull);
  });

  testWidgets('opens the url when the link is tapped', (tester) async {
    await pump(tester, 'watch https://youtu.be/dQw4w9WgXcQ now');

    tapLink(tester, 'https://youtu.be/dQw4w9WgXcQ');

    expect(tapped, ['https://youtu.be/dQw4w9WgXcQ']);
  });

  testWidgets('opens the href, not the displayed text, for a bare www link',
      (tester) async {
    await pump(tester, 'see www.example.com');

    tapLink(tester, 'www.example.com');

    expect(tapped, ['https://www.example.com']);
  });

  testWidgets('keeps the surrounding words as plain spans', (tester) async {
    await pump(tester, 'before https://example.com/a after');

    final span = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
    final texts = <String>[];
    span.visitChildren((child) {
      if (child is TextSpan && child.text != null) texts.add(child.text!);
      return true;
    });

    expect(texts, ['before ', 'https://example.com/a', ' after']);
  });

  testWidgets('a tap away from the link still reaches the card', (tester) async {
    var cardTaps = 0;
    await pump(tester, 'no links in this one',
        onBackgroundTap: () => cardTaps++);

    await tester.tap(find.byType(LinkifiedText));

    // This is the behaviour the post card depends on: linkifying the body
    // must not swallow the gesture that opens the post.
    expect(cardTaps, 1);
  });

  testWidgets('releases its recognizers when the text changes', (tester) async {
    await pump(tester, 'a https://one.example/x b');
    await pump(tester, 'a https://two.example/y b');

    // A stale recognizer would still be in the arena and would fire the old
    // URL. Only the current link may respond.
    tapLink(tester, 'https://two.example/y');
    expect(tapped, ['https://two.example/y']);
  });

  testWidgets('disposes cleanly', (tester) async {
    await pump(tester, 'x https://example.com/a y');
    await tester.pumpWidget(const SizedBox.shrink());

    // A leaked TapGestureRecognizer fails the binding's debug assertions at
    // the end of the test rather than here.
    expect(find.byType(LinkifiedText), findsNothing);
  });
}
