/// Finds the links inside a piece of user-written text.
///
/// Pure and total, so the fiddly parts — where a link stops, what counts as
/// one — are testable without pumping a widget. [LinkifiedText] renders what
/// this returns.
library;

/// One link found in a string.
class LinkMatch {
  const LinkMatch({
    required this.start,
    required this.end,
    required this.text,
    required this.url,
  });

  /// Index of the first character of the link in the source string.
  final int start;

  /// Index just past the last character.
  final int end;

  /// Exactly what the user typed, which is what gets displayed. Shown rather
  /// than [url] so a bare `www.example.com` is not silently rewritten on
  /// screen into something the author did not write.
  final String text;

  /// The absolute URL to open. Equal to [text] except when a scheme had to be
  /// added.
  final String url;

  @override
  String toString() => 'LinkMatch($start-$end, $url)';
}

/// Characters that routinely sit *after* a URL in prose and are not part of
/// it. A trailing `)` is handled separately — it may legitimately belong to
/// the URL, as in a Wikipedia article title.
const _trailingPunctuation = '.,;:!?\'"«»…-–—';

/// Matches an absolute http(s) URL, or a bare host beginning `www.`.
///
/// Deliberately permissive about the path — a URL may contain almost
/// anything — and deliberately strict about where it *starts*: preceded by
/// whitespace or the beginning of the string, so `foo@www.example.com` and the
/// tail of an already-matched URL are not treated as new links.
final _linkRe = RegExp(
  r'(?<=^|\s)((?:https?://|www\.)[^\s<>"]+)',
  caseSensitive: false,
  multiLine: true,
);

/// Finds every link in [text], in order.
///
/// Returns an empty list for text with no links, which is the common case and
/// lets callers skip building rich text entirely.
List<LinkMatch> scanLinks(String text) {
  if (text.isEmpty) return const [];

  final matches = <LinkMatch>[];
  for (final m in _linkRe.allMatches(text)) {
    final raw = m.group(1);
    if (raw == null || raw.isEmpty) continue;

    final trimmed = _trimTrailing(raw);
    if (trimmed.isEmpty) continue;

    // `https://` on its own, or `www.` on its own, is not a link.
    final url = _withScheme(trimmed);
    if (!_hasHost(url)) continue;

    matches.add(LinkMatch(
      start: m.start,
      end: m.start + trimmed.length,
      text: trimmed,
      url: url,
    ));
  }
  return matches;
}

/// True when [text] contains at least one link.
bool containsLink(String text) => scanLinks(text).isNotEmpty;

/// Drops sentence punctuation that the regex swept up.
///
/// A closing bracket survives only if the URL opened one, so
/// `…/Foo_(bar)` keeps its parenthesis while `(see https://x.example/a)` does
/// not eat the one that closes the aside.
String _trimTrailing(String raw) {
  var end = raw.length;

  while (end > 0) {
    final ch = raw[end - 1];

    if (_trailingPunctuation.contains(ch)) {
      end--;
      continue;
    }

    if (ch == ')' || ch == ']' || ch == '}') {
      final open = ch == ')' ? '(' : (ch == ']' ? '[' : '{');
      // Everything before the bracket under test. Including it would count it
      // against itself, so `…/Foo_(bar)` looked balanced-without-it and got
      // trimmed to a URL that 404s.
      final body = raw.substring(0, end - 1);
      // An unmatched opener earlier in the URL means this bracket closes it.
      // Otherwise the bracket closes something in the surrounding prose.
      if (_count(body, open) > _count(body, ch)) break;
      end--;
      continue;
    }

    break;
  }

  return raw.substring(0, end);
}

int _count(String s, String ch) {
  var n = 0;
  for (var i = 0; i < s.length; i++) {
    if (s[i] == ch) n++;
  }
  return n;
}

/// `www.example.com` is a link to a human and not a URL to [Uri]. Give it the
/// scheme it implies rather than dropping it.
String _withScheme(String raw) =>
    raw.toLowerCase().startsWith('www.') ? 'https://$raw' : raw;

bool _hasHost(String url) {
  final uri = Uri.tryParse(url);
  return uri != null && uri.host.isNotEmpty && uri.host.contains('.');
}
