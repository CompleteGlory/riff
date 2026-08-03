import 'dart:async';

/// Keeps at most one voice note audible at a time.
///
/// Every voice-note bubble owns its own `AudioPlayer`, and nothing used to
/// arbitrate between them: starting a second note left the first one playing
/// underneath it, so scrolling a chat with a few voice messages ended up with
/// several talking over each other and no obvious way to silence them except
/// finding each bubble again.
///
/// A process-wide singleton rather than something scoped to the chat screen —
/// a note left playing while the user navigates away is exactly the case that
/// needs stopping, and there is no widget still around to do it.
///
/// Callers identify themselves with an [owner] token (the bubble's `State`
/// object) instead of by comparing callbacks, so the bookkeeping doesn't
/// depend on how Dart canonicalises tear-offs.
class VoiceNotePlayback {
  VoiceNotePlayback._();

  static VoiceNotePlayback _instance = VoiceNotePlayback._();
  static VoiceNotePlayback get instance => _instance;

  /// Drops the singleton's state between tests — it outlives any one of them.
  static void resetInstanceForTest() => _instance = VoiceNotePlayback._();

  Object? _owner;
  Future<void> Function()? _stop;

  /// The note currently allowed to play, or null when nothing is.
  Object? get currentOwner => _owner;

  /// Hands playback to [owner], silencing whatever held it before.
  ///
  /// [stop] is how this note is silenced when someone else claims it later.
  /// Awaiting the previous note's stop before returning means the caller can
  /// start playing immediately afterwards without the two overlapping.
  Future<void> claim(Object owner, Future<void> Function() stop) async {
    final previousStop = _stop;
    final hadOther = _owner != null && !identical(_owner, owner);

    _owner = owner;
    _stop = stop;

    if (hadOther && previousStop != null) await previousStop();
  }

  /// Gives up playback, if [owner] still holds it.
  ///
  /// Guarded on ownership because a note that finished — or a bubble being
  /// disposed as the list scrolls — can land *after* another note has already
  /// claimed playback, and an unguarded release would clear the newcomer's
  /// claim and let a third note start on top of it.
  void release(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _stop = null;
  }

  /// Silences whatever is playing. Used when leaving the conversation.
  Future<void> stopAll() async {
    final stop = _stop;
    _owner = null;
    _stop = null;
    if (stop != null) await stop();
  }
}
