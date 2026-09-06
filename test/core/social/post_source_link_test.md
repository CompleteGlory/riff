# `post_source_link_test.dart`

## What it covers

Which external thing a post points at, and how confident we are about it.

`source_url` / `source_platform` are written **only** when a post is created
through the system share sheet. Anyone who pasted a YouTube link into the
composer — which is how most of them arrive — produced a post with those
columns null and the URL sitting in the body. Those posts had no affordance at
all before links were pressable, and a bare underlined link afterwards. This
resolver closes that gap for every post already in the database, with no
migration and without rewriting anyone's content.

| Post | Result |
| --- | --- |
| shared, url + platform stored | that url, that platform |
| shared, url stored, platform null | that url, platform **derived from the host** |
| shared from an unknown host | that url, `platform: null` — a neutral "Open link" badge |
| pasted YouTube link in the body | that link, YouTube |
| pasted `https://example.com/a` in the body | **nothing** |
| stored url *and* a different link in the body | the stored url wins |
| platform recorded with no url | nothing |

## The asymmetry is the design

An unknown *stored* share still gets a badge; an unknown link *in the body*
does not. A share is a statement of intent — the user chose to send that thing
— whereas a URL inside a sentence is often incidental. Putting a full-width
branded chip under every post that happens to mention a website would be worse
than leaving it as the pressable link it already is.

## Why deriving the platform from the host matters

`derives the platform when only the url was stored` is the case that fixes
history. Every YouTube link shared into an older build kept its URL and got a
null platform, because nothing recognised the host at the time. Falling back to
`SocialPlatform.fromUrl` brands those retroactively.

## What's mocked

Nothing. Pure function over three nullable strings.
