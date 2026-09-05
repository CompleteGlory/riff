import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/utils/link_scanner.dart';

/// See link_scanner_test.md for what this covers and why.
void main() {
  List<String> urls(String text) => scanLinks(text).map((m) => m.url).toList();

  group('finding links', () {
    test('finds nothing in text with no links', () {
      expect(scanLinks('just some words'), isEmpty);
      expect(scanLinks(''), isEmpty);
      expect(containsLink('no links here'), isFalse);
    });

    test('finds a bare url', () {
      expect(urls('https://example.com/a'), ['https://example.com/a']);
    });

    test('finds a url in the middle of a sentence', () {
      expect(urls('look at https://example.com/a it is good'),
          ['https://example.com/a']);
    });

    test('finds several, in order', () {
      expect(urls('https://a.example/1 and https://b.example/2'),
          ['https://a.example/1', 'https://b.example/2']);
    });

    test('gives a scheme to a bare www host', () {
      final match = scanLinks('see www.example.com now').single;
      // What the author typed is what is displayed; only the href is rewritten.
      expect(match.text, 'www.example.com');
      expect(match.url, 'https://www.example.com');
    });

    test('reports the span so the surrounding text can be rebuilt around it',
        () {
      const text = 'go to https://example.com/a ok';
      final match = scanLinks(text).single;
      expect(text.substring(match.start, match.end), 'https://example.com/a');
    });
  });

  group('where a link stops', () {
    test('drops a full stop that ends the sentence', () {
      expect(urls('read https://example.com/a.'), ['https://example.com/a']);
    });

    test('drops other sentence punctuation', () {
      expect(urls('here: https://example.com/a, and'), ['https://example.com/a']);
      expect(urls('really https://example.com/a!'), ['https://example.com/a']);
    });

    test('does not eat a bracket that closes the sentence, not the url', () {
      expect(urls('(see https://example.com/a)'), ['https://example.com/a']);
    });

    test('keeps a bracket the url itself opened', () {
      // A Wikipedia article title is the everyday case, and trimming it
      // produces a URL that 404s rather than one that is merely ugly.
      expect(urls('https://en.wikipedia.org/wiki/Foo_(bar)'),
          ['https://en.wikipedia.org/wiki/Foo_(bar)']);
    });

    test('keeps query strings and fragments intact', () {
      expect(urls('https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s'),
          ['https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s']);
    });
  });

  group('what is not a link', () {
    test('an email address is not one, and its host is not extracted', () {
      // The lookbehind is what stops `www.example.com` being pulled out of
      // `someone@www.example.com` as though it were a separate link.
      expect(scanLinks('mail someone@www.example.com please'), isEmpty);
    });

    test('a scheme with no host', () {
      expect(scanLinks('https://'), isEmpty);
    });

    test('a hostless word that merely starts with www', () {
      expect(scanLinks('wwwfoo'), isEmpty);
    });

    test('a bare domain without www is left alone', () {
      // Deliberate: linkifying every dotted word turns "etc.Then" and file
      // names into links. A user who wants a link types a scheme or www.
      expect(scanLinks('example.com is a site'), isEmpty);
    });
  });

  test('handles a link inside right-to-left text', () {
    // The app is bilingual; a URL in an Arabic caption has to come out with
    // the same span the Latin case does.
    const text = 'شاهد هذا https://youtu.be/dQw4w9WgXcQ شكرا';
    final match = scanLinks(text).single;
    expect(match.url, 'https://youtu.be/dQw4w9WgXcQ');
    expect(text.substring(match.start, match.end), 'https://youtu.be/dQw4w9WgXcQ');
  });
}
