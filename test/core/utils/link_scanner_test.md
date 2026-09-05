# `link_scanner_test.dart`

## What it covers

`scanLinks` is the pure half of making links pressable: it decides what counts
as a link in user-written text and, crucially, **where one stops**. Every case
here is a way that boundary can be got wrong.

| Input | Expected |
| --- | --- |
| `read https://example.com/a.` | link without the full stop |
| `(see https://example.com/a)` | link without the closing bracket |
| `https://en.wikipedia.org/wiki/Foo_(bar)` | link **with** the bracket |
| `www.example.com` | displayed as typed, opened as `https://…` |
| `someone@www.example.com` | no link at all |
| `example.com is a site` | no link |
| Arabic text around a URL | correct span |

## Why the bracket cases are separate

Trailing punctuation and a trailing bracket look like the same problem and are
not. `.` after a URL is never part of it; `)` usually is not, but is whenever
the URL opened one — which is the Wikipedia case, and the difference between a
working link and a 404. The rule is balance, not the character.

## Why `example.com` deliberately does not linkify

Matching bare dotted words turns `etc.Then`, `v1.2` and file names into links.
The cost of missing a bare domain is that the user types four more characters;
the cost of over-matching is prose with underlined fragments in it.

## What's mocked

Nothing. Pure function, no I/O, no widgets.
