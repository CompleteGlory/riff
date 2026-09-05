# `social_platform_test.dart`

## What it covers

`SocialPlatform` is the single source of truth for the platforms a Riff post
can come from. It replaced four hand-written copies of the same if-chain (the
feed chip, the full-screen reel card, the small reel badge, the create-post
banner), each of which had the same defect:

```dart
if (_isInstagram) return <instagram value>;
if (_isTikTok)    return <tiktok value>;
return <spotify value>;          // no neutral default
```

So the tests fall into two halves.

**Resolution has to fail closed.** `maybeFromKey` returns null for anything it
does not know, and the branding getters have neutral fallbacks. The old shape
meant a platform nobody had written a branch for rendered as Spotify — the
green chip and "Play on Spotify" on a YouTube post — which is worse than
rendering nothing, because it is confidently wrong.

**Detection has to match the host.** `fromUrl` parses the URL and compares
whole dot-separated labels. The three negative cases are the point:

| URL | Contains "youtube.com" | Is YouTube |
| --- | --- | --- |
| `https://notyoutube.com/watch?v=x` | yes | **no** |
| `https://youtube.com.phish.example/…` | yes | **no** |
| `https://evil.example/?next=https://youtube.com/x` | yes | **no** |

The `url.contains('youtube.com')` test this replaced answered yes to all three.
That matters beyond cosmetics: the same classification runs server-side in
`MetaService`, on a `@Public()` endpoint that then *fetches* the URL, so it
decides which host the API is pointed at.

## The cross-repo contract

`the wire keys are exactly what the API accepts` pins the four strings against
a literal list. They must equal the zod enum in `create-post.dto.ts` and the
keys in `MetaService.HOSTS`. Nothing checks that at build time — a rename that
is not mirrored surfaces as posts failing validation at creation.

## What's mocked

Nothing. Pure enum and pure functions.
