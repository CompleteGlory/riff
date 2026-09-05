import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/utils/link_scanner.dart';

/// Text with its links pressable.
///
/// Every place the app showed user-written text — a post body, a chat bubble,
/// a reel caption — rendered a plain [Text], so a URL someone pasted was dead
/// characters on screen. The only way to follow one was to long-press, copy
/// the entire body, leave Riff, and paste it into a browser.
///
/// Two things make this more than a `Text.rich`:
///
/// **The gesture arena.** A post card is wrapped in a `GestureDetector` that
/// opens the post, and a `TapGestureRecognizer` on a span competes with it.
/// That resolves the way it should: the span's recognizer only enters the
/// arena for a touch that lands on the link's own glyphs, so tapping a link
/// opens the link and tapping anywhere else in the paragraph still opens the
/// post. Long-press-to-copy is untouched, because these recognizers claim
/// taps only.
///
/// **Recognizers are disposable.** A `TapGestureRecognizer` holds an entry in
/// the gesture arena and leaks if it outlives its span, so they are owned by
/// the [State], rebuilt when the text changes, and disposed with it. A
/// `StatelessWidget` here would leak one recognizer per link per rebuild —
/// in a scrolling feed, continuously.
class LinkifiedText extends StatefulWidget {
  const LinkifiedText({
    super.key,
    required this.text,
    required this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.onLinkTap = _launch,
  });

  final String text;
  final TextStyle style;

  /// Defaults to [style] in the accent colour with an underline.
  final TextStyle? linkStyle;

  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// Opens a tapped link. Injectable so a widget test can assert which URL was
  /// tapped without a plugin — the pattern the login tests established for
  /// anything platform-backed.
  final Future<void> Function(String url) onLinkTap;

  static Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    // A link in a post is somebody else's URL. It opens in the browser, never
    // inside a Riff webview, so the address bar is visible and Riff is not
    // sitting between the user and a page it does not control.
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];
  List<LinkMatch> _links = const [];

  @override
  void initState() {
    super.initState();
    _links = scanLinks(widget.text);
  }

  @override
  void didUpdateWidget(LinkifiedText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _disposeRecognizers();
      _links = scanLinks(widget.text);
    }
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No links: the ordinary widget, with none of the machinery above. This is
    // the overwhelmingly common case and it should cost nothing.
    if (_links.isEmpty) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: widget.textAlign,
      );
    }

    // Recognizers are rebuilt with the spans; the previous set is released
    // first so a rebuild does not strand them in the arena.
    _disposeRecognizers();

    final linkColor = ColorManager.link(Theme.of(context).brightness);
    final linkStyle = widget.linkStyle ??
        widget.style.copyWith(
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
        );

    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final link in _links) {
      if (link.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, link.start)));
      }

      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onLinkTap(link.url);
      _recognizers.add(recognizer);

      spans.add(TextSpan(
        text: link.text,
        style: linkStyle,
        recognizer: recognizer,
        // Read out as a link rather than as a run of punctuation and slashes.
        semanticsLabel: link.text,
      ));

      cursor = link.end;
    }

    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: widget.style, children: spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow ?? TextOverflow.clip,
      textAlign: widget.textAlign,
    );
  }
}
