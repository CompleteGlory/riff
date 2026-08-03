// ignore_for_file: unused_field

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/features/home/chat/logic/cubit/chat_cubit.dart';
import 'package:riff/generated/l10n.dart';

class ChatInputBar extends StatefulWidget {
  final ChatCubit cubit;
  const ChatInputBar({super.key, required this.cubit});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  Timer? _typingTimer;

  /// The message being rewritten, mirrored from the cubit.
  ///
  /// "Edit" is tapped in the long-press sheet, nowhere near the composer, so
  /// the cubit owns the flag and this bar follows it rather than being told
  /// directly.
  ChatMessage? _editing;

  /// The message being quoted, mirrored from the cubit for the same reason as
  /// [_editing] — "Reply" is tapped on the bubble, not here.
  ChatMessage? _replyingTo;
  StreamSubscription<ChatState>? _stateSub;

  // Recording
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  /// True while the recording is held mid-take. The file stays open and
  /// resuming appends to it, so the result is one continuous voice note rather
  /// than several the user would have to send separately.
  bool _isPaused = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _syncEditing(widget.cubit.state);
    _stateSub = widget.cubit.stream.listen(_syncEditing);
  }

  /// Opens or closes edit mode to match the cubit.
  ///
  /// Only acts on a *change* of which message is being edited: the cubit emits
  /// on every incoming message and read receipt, and reloading the field on
  /// each of those would wipe out whatever the user had typed since.
  void _syncEditing(ChatState state) {
    final replying = state is ChatLoaded ? state.replyingTo : null;
    if (replying?.id != _replyingTo?.id) {
      setState(() => _replyingTo = replying);
      // Starting a reply focuses the field but leaves whatever is typed
      // alone — a half-written message shouldn't be lost to answering someone.
      if (replying != null) _focusNode.requestFocus();
    }

    final editing = state is ChatLoaded ? state.editingMessage : null;
    if (editing?.id == _editing?.id) return;
    setState(() => _editing = editing);
    if (editing != null) {
      _controller.text = editing.content ?? '';
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
      _focusNode.requestFocus();
    } else {
      _controller.clear();
    }
  }

  void _cancelEdit() {
    // The cubit clearing it is what drives _syncEditing to reset the field.
    widget.cubit.cancelEditing();
  }

  Future<void> _submitEdit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final ok = await widget.cubit.submitEdit(text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).messageEditFailed)),
      );
    }
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);

    // Rewriting an existing message isn't "typing" — the other side sees no
    // indicator for it, since nothing new is on its way to them.
    if (_editing != null) return;

    if (has) {
      widget.cubit.startTyping();
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        widget.cubit.stopTyping();
      });
    } else {
      _typingTimer?.cancel();
      widget.cubit.stopTyping();
    }
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _typingTimer?.cancel();
    widget.cubit.stopTyping();

    // The bubble is already on screen, dimmed, and turns into a tappable
    // "not sent · retry" if this fails — so the composer stays cleared. Putting
    // the text back (what this used to do) would leave the user with the same
    // message in two places.
    await widget.cubit.sendText(text);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final name = file.name;
    final mime = _mimeFromExt(name.split('.').last);
    widget.cubit.sendMedia(file.path, name, mime);
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
    if (file == null) return;
    final name = file.name;
    widget.cubit.sendMedia(file.path, name, 'video/mp4');
  }

  String _mimeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      case 'gif':  return 'image/gif';
      case 'webp': return 'image/webp';
      default:     return 'image/jpeg';
    }
  }

  void _showMediaPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Photo'),
            onTap: () { Navigator.pop(context); _pickImage(); },
          ),
          ListTile(
            leading: const Icon(Icons.videocam_outlined),
            title: const Text('Video'),
            onTap: () { Navigator.pop(context); _pickVideo(); },
          ),
        ]),
      ),
    );
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')));
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _recordingPath = path;

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordDuration = Duration.zero;
    });

    _startTicking();
  }

  /// Runs the elapsed counter. Separate from `_startRecording` because resuming
  /// has to restart it from the duration already banked, not from zero.
  void _startTicking() {
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  /// Holds the recording, or picks it up again from where it stopped.
  ///
  /// The counter is stopped rather than reset: a paused recording keeps the
  /// seconds it has already captured, since resuming appends to the same file.
  Future<void> _togglePauseRecording() async {
    if (_isPaused) {
      await _audioRecorder.resume();
      if (!mounted) return;
      setState(() => _isPaused = false);
      _startTicking();
    } else {
      await _audioRecorder.pause();
      _recordTimer?.cancel();
      if (!mounted) return;
      setState(() => _isPaused = true);
    }
  }

  Future<void> _stopAndSend() async {
    _recordTimer?.cancel();
    // stop() finalises a paused recording too, so there is no need to resume
    // first — the parts recorded either side of the pause are already one file.
    final path = await _audioRecorder.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!await file.exists() || await file.length() < 1000) {
      // Too short — discard
      try {
        await file.delete();
      } catch (_) {
        // ignore
      }
      return;
    }

    final durationSecs = _recordDuration.inSeconds;
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    widget.cubit.sendMedia(path, fileName, 'audio/mp4', duration: durationSecs);
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _audioRecorder.cancel();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _recordTimer?.cancel();
    _stateSub?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isRecording) {
      return _RecordingBar(
        duration: _recordDuration,
        isDark: isDark,
        isPaused: _isPaused,
        onSend: _stopAndSend,
        onCancel: _cancelRecording,
        onTogglePause: _togglePauseRecording,
        formatDuration: _formatDuration,
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_editing != null)
            _EditingBanner(
              message: _editing!,
              isDark: isDark,
              onCancel: _cancelEdit,
            )
          // Never both: the cubit keeps editing and replying mutually
          // exclusive, so the composer only ever shows one banner.
          else if (_replyingTo != null)
            _ReplyBanner(
              message: _replyingTo!,
              isDark: isDark,
              onCancel: widget.cubit.cancelReplying,
            ),
          Row(children: [
          // Attaching media is composing a new message, not rewriting one.
          if (_editing == null) ...[
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded,
                  color:
                      isDark ? ColorManager.lightGrey : ColorManager.darkGrey),
              onPressed: _showMediaPicker,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
            ),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Container(
              constraints: BoxConstraints(maxHeight: 120.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 15,
                  color: isDark ? ColorManager.white : ColorManager.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Message…',
                  hintStyle: TextStyle(
                    fontFamily: 'GeneralSans',
                    color: isDark ? ColorManager.normalGrey : ColorManager.lightGrey,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _editing != null
                // No mic while editing: an empty field means "the message you
                // are rewriting", not "record a voice note".
                ? GestureDetector(
                    key: const ValueKey('saveEdit'),
                    onTap: _hasText ? _submitEdit : null,
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: _hasText
                            ? ColorManager.accent
                            : ColorManager.accent.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: ColorManager.black, size: 20),
                    ),
                  )
                : _hasText
                ? GestureDetector(
                    key: const ValueKey('send'),
                    onTap: _sendText,
                    child: Container(
                      width: 40.w, height: 40.h,
                      decoration: const BoxDecoration(
                        color: ColorManager.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded,
                          color: ColorManager.black, size: 20),
                    ),
                  )
                : GestureDetector(
                    key: const ValueKey('mic'),
                    onLongPress: _startRecording,
                    onTap: _startRecording,
                    child: Container(
                      width: 40.w, height: 40.h,
                      alignment: Alignment.center,
                      child: Icon(Icons.mic_none_rounded,
                          color: isDark ? ColorManager.lightGrey : ColorManager.darkGrey),
                    ),
                  ),
          ),
        ]),
        ]),
      ),
    );
  }
}

// ─── Editing banner ───────────────────────────────────────────────────────────

/// The strip above the composer while a message is being rewritten, showing
/// which one — without it, edit mode is indistinguishable from having typed
/// the same text again.
class _EditingBanner extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final VoidCallback onCancel;

  const _EditingBanner({
    required this.message,
    required this.isDark,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(children: [
        Container(width: 3.w, height: 34.h, color: ColorManager.accent),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.of(context).editingMessageTitle,
                style: TextStyles.font12semiBold
                    .copyWith(color: ColorManager.accent),
              ),
              Text(
                message.content ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.font12regular
                    .copyWith(color: ColorManager.normalGrey),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          tooltip: S.of(context).cancelEditTooltip,
          onPressed: onCancel,
          color: isDark ? ColorManager.lightGrey : ColorManager.darkGrey,
        ),
      ]),
    );
  }
}

// ─── Reply banner ─────────────────────────────────────────────────────────────

/// The strip above the composer while a message is being answered, so the reply
/// is visibly attached to something before it is sent.
class _ReplyBanner extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final VoidCallback onCancel;

  const _ReplyBanner({
    required this.message,
    required this.isDark,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final name = message.sender?.username ?? message.sender?.fullName ?? '';
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(children: [
        Container(width: 3.w, height: 34.h, color: ColorManager.accent),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.of(context).replyingToLabel(name),
                style: TextStyles.font12semiBold
                    .copyWith(color: ColorManager.accent),
              ),
              Text(
                message.preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.font12regular
                    .copyWith(color: ColorManager.normalGrey),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          tooltip: S.of(context).cancelReplyTooltip,
          onPressed: onCancel,
          color: isDark ? ColorManager.lightGrey : ColorManager.darkGrey,
        ),
      ]),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  final Duration duration;
  final bool isDark;
  final bool isPaused;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onTogglePause;
  final String Function(Duration) formatDuration;

  /// Identifies the pause/resume control for tests.
  static const pauseKey = Key('recordingPauseButton');

  const _RecordingBar({
    required this.duration,
    required this.isDark,
    required this.isPaused,
    required this.onSend,
    required this.onCancel,
    required this.onTogglePause,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          // Cancel
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: ColorManager.red),
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
          ),
          SizedBox(width: 8.w),
          // Recording indicator + timer
          Expanded(
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(22.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(children: [
                // The dot stops pulsing while paused — a blinking red dot next
                // to a frozen counter reads as a bug, not as "held".
                if (isPaused)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ColorManager.normalGrey,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  _PulsingDot(),
                SizedBox(width: 8.w),
                Text(
                  '${isPaused ? S.of(context).recordingPaused : S.of(context).recordingInProgress}  ${formatDuration(duration)}',
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 14,
                    color: isDark ? ColorManager.white : ColorManager.black,
                  ),
                ),
              ]),
            ),
          ),
          SizedBox(width: 8.w),
          // Pause / resume
          GestureDetector(
            key: pauseKey,
            onTap: onTogglePause,
            child: Container(
              width: 40.w,
              height: 40.h,
              alignment: Alignment.center,
              child: Icon(
                isPaused ? Icons.fiber_manual_record_rounded : Icons.pause_rounded,
                color: isPaused
                    ? ColorManager.red
                    : (isDark ? ColorManager.lightGrey : ColorManager.darkGrey),
                size: 22,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          // Send
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 40.w, height: 40.h,
              decoration: const BoxDecoration(
                color: ColorManager.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: ColorManager.black, size: 18),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(
          color: ColorManager.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
