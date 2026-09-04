# `camera_capture_test.dart`

Covers `CameraCapture` and `CameraMode` — the value object the in-app camera
hands back, and the two capture modes.

## Why a value object rather than a bare File

Every caller has to know *which kind* of media came back. A post appends it to
a list that renders photos and videos differently; chat has to choose a MIME
type before uploading. Passing a `File` around means each call site re-derives
that from the extension, which is how the same rule ends up written three times
and then drifts.

## What it covers

- a still reports `image/jpeg`, a recording reports `video/mp4`
- **the MIME type comes from what was captured, not from the path.** The plugin
  chooses the container; a call site sniffing the extension would mislabel a
  file written with an unexpected suffix, and the API branches on this value
- `name` is the basename, so an upload is not named after a temp directory
- `CameraMode` still has both cases

## Gotchas

- The `CameraMode` assertion looks trivial. It is there because the mode switch
  is the only route to video that does not require holding the shutter down —
  deleting a case would quietly remove the press-free path and no other test
  would notice.
- The screen itself (`RiffCameraScreen`) is not unit tested: it needs a live
  `CameraController`, which has no useful fake. Its logic is deliberately thin
  for that reason, and it is verified by building and running on a device.
