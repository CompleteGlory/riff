# `media_url_test.dart`

Covers `MediaUrl`, the one place media URLs from the API are turned into URLs
the app loads — and, since videos started crashing playback, the one place the
video codec is decided.

## Why `videoStream` exists

Phones record HEVC (H.265). Cloudinary stored whatever arrived, so a clip shot
on one phone was delivered untouched to every other. A tester's Android device
crashed on it with `PlatformException(VideoError, … MediaCodecVideoRenderer
error … video/hevc …)`, reported as a fatal, *unhandled* error — the container
even claimed `format_supported=YES`, which is why it was not caught anywhere.

Uploads are transcoded to H.264 on the server now, but the clips posted before
that are still HEVC in storage. `videoStream` pins the codec on the way out
instead, so those existing posts play without anyone re-uploading them.
Cloudinary builds the H.264 rendition once and caches it.

## What it covers

- `resolve`: absolute URLs pass through, legacy relative paths resolve against
  the API base, null/empty give null
- `videoStream`: rewrites a Cloudinary video URL to carry
  `f_mp4,vc_h264,q_auto`, for both `.mp4` and iPhone `.mov`
- **voice notes are left alone** — Cloudinary files audio under the `video`
  resource type, so the naive rule would ask it to build a video track that
  does not exist
- images, non-Cloudinary URLs and already-transformed URLs are untouched
- relative paths still resolve, and a URL with no extension still transforms

## Gotchas

- The audio exclusion is the subtle one. `/video/upload/` in a URL does **not**
  mean the asset is video; the extension is what separates a reel from a voice
  note.
- The "does not stack" test matters because these URLs are round-tripped
  through models and caches: transforming an already-transformed URL would
  produce a 400 from Cloudinary rather than a silently worse video.
