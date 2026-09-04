# `device_gallery_test.dart`

Covers the small parts of `DeviceGallery` that can be asserted without a real
photo library: the access states and the paging size.

## Why the coverage is thin

`DeviceGallery` is deliberately a thin wrapper over `photo_manager`, which
talks to the platform. Everything interesting about it — permission prompts,
album resolution, thumbnail decoding, resolving an iCloud asset to a file —
happens on the device and has no useful fake. Wrapping it at all is what keeps
the widgets above it testable, so the wrapper itself is the one place where
verification stops.

## What it covers

- **`limited` is its own state.** iOS lets someone share only a few photos.
  Collapsing that into `denied` would blank the strip for a user who *did*
  grant access, and hide the affordance that lets them widen it.
- The gallery pages rather than reading everything. A phone library runs to
  tens of thousands of items and the camera opening is the moment the user is
  waiting on.

## Verified on a device instead

Permission prompts on both platforms, an empty library, a library of thousands
(paging while scrolling), an iCloud photo that has to download before it
resolves, and the Android 13 split between `READ_MEDIA_IMAGES` and the legacy
`READ_EXTERNAL_STORAGE`.
