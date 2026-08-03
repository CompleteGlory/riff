import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/home/chat/logic/voice_note_playback.dart';

/// See voice_note_playback_test.md for what this covers and why.
void main() {
  /// Stands in for a voice-note bubble: an identity to claim with, and a
  /// record of whether it was asked to stop.
  Object owner(String name) => _Owner(name);

  setUp(VoiceNotePlayback.resetInstanceForTest);

  test('the first note to claim keeps playing', () async {
    final a = owner('a');
    var stopped = false;

    await VoiceNotePlayback.instance.claim(a, () async => stopped = true);

    expect(stopped, isFalse);
    expect(VoiceNotePlayback.instance.currentOwner, a);
  });

  test('a second note stops the first', () async {
    final a = owner('a');
    final b = owner('b');
    var aStopped = false;

    await VoiceNotePlayback.instance.claim(a, () async => aStopped = true);
    await VoiceNotePlayback.instance.claim(b, () async {});

    expect(aStopped, isTrue);
    expect(VoiceNotePlayback.instance.currentOwner, b);
  });

  // Tapping play on the note that already holds playback — after pausing it
  // from its own button, say — must not stop it on the way back in.
  test('re-claiming by the same note does not stop it', () async {
    final a = owner('a');
    var stopCount = 0;

    await VoiceNotePlayback.instance.claim(a, () async => stopCount++);
    await VoiceNotePlayback.instance.claim(a, () async => stopCount++);

    expect(stopCount, 0);
  });

  test('release clears the claim', () async {
    final a = owner('a');
    await VoiceNotePlayback.instance.claim(a, () async {});

    VoiceNotePlayback.instance.release(a);

    expect(VoiceNotePlayback.instance.currentOwner, isNull);
  });

  // A note that finished — or a bubble disposed as the list scrolls — can
  // report in *after* another note has already taken over. An unguarded
  // release would clear the newcomer's claim, and a third note would then
  // start without stopping it.
  test('a stale release does not clear someone else\'s claim', () async {
    final a = owner('a');
    final b = owner('b');
    await VoiceNotePlayback.instance.claim(a, () async {});
    await VoiceNotePlayback.instance.claim(b, () async {});

    VoiceNotePlayback.instance.release(a);

    expect(VoiceNotePlayback.instance.currentOwner, b,
        reason: 'the late release belongs to a note that already lost the claim');
  });

  test('stopAll silences whatever is playing', () async {
    final a = owner('a');
    var stopped = false;
    await VoiceNotePlayback.instance.claim(a, () async => stopped = true);

    await VoiceNotePlayback.instance.stopAll();

    expect(stopped, isTrue);
    expect(VoiceNotePlayback.instance.currentOwner, isNull);
  });

  test('stopAll on silence is harmless', () async {
    await VoiceNotePlayback.instance.stopAll();

    expect(VoiceNotePlayback.instance.currentOwner, isNull);
  });

  // claim() awaits the previous note's stop before returning, so the caller
  // can start playing straight afterwards without the two overlapping.
  test('claim waits for the previous note to actually stop', () async {
    final a = owner('a');
    final b = owner('b');
    var aStopped = false;

    await VoiceNotePlayback.instance.claim(a, () async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      aStopped = true;
    });

    await VoiceNotePlayback.instance.claim(b, () async {});

    expect(aStopped, isTrue);
  });
}

class _Owner {
  _Owner(this.name);
  final String name;
}
