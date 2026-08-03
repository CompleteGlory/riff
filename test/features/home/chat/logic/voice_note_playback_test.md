# `voice_note_playback_test.dart`

Covers `VoiceNotePlayback` — the coordinator that keeps at most one voice note
audible at a time.

## Why it exists

Every voice-note bubble owns its own `AudioPlayer` and nothing arbitrated
between them, so starting a second note left the first playing underneath it. A
chat with a few voice messages ended up with several talking over each other,
and the only way to stop one was to scroll back and find its bubble again.

It's a process-wide singleton rather than something scoped to the chat screen,
because the case that most needs stopping — a note still playing after the user
navigates away — is exactly the one where no widget is left to do it.

## What it covers

- the first note to claim keeps playing
- a second note stops the first
- re-claiming by the **same** note doesn't stop it (tapping play again after
  pausing from its own button)
- `release` clears the claim
- a **stale** release doesn't clear someone else's claim. A note that finished,
  or a bubble disposed as the list scrolls, can report in after another note has
  already taken over; an unguarded release would clear the newcomer's claim and
  let a third note start on top of it
- `stopAll` silences the current note, and is harmless when nothing is playing
- `claim` **awaits** the previous note's stop before returning, so the caller
  can start playing immediately afterwards without the two overlapping

## Mocks

None, and no audio. Ownership is an opaque token (`_Owner`) and "stopping" is a
callback that flips a flag — the coordinator never touches a player itself,
which is what makes it testable without the plugin.

## Gotchas

`VoiceNotePlayback.resetInstanceForTest()` in `setUp` — like `OfflineCache` and
`ConnectivityService`, the singleton outlives any one test, and a claim left
over from an earlier one would make the next test's first claim stop a
phantom.
