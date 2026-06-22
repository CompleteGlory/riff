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
import 'package:riff/features/home/chat/logic/cubit/chat_cubit.dart';

class ChatInputBar extends StatefulWidget {
  final ChatCubit cubit;
  const ChatInputBar({super.key, required this.cubit});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;
  Timer? _typingTimer;

  // Recording
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);

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

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.cubit.sendText(text);
    _controller.clear();
    _typingTimer?.cancel();
    widget.cubit.stopTyping();
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
      _recordDuration = Duration.zero;
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _stopAndSend() async {
    _recordTimer?.cancel();
    final path = await _audioRecorder.stop();
    if (!mounted) return;
    setState(() => _isRecording = false);

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
    if (mounted) setState(() => _isRecording = false);
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
        onSend: _stopAndSend,
        onCancel: _cancelRecording,
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
        child: Row(children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded,
                color: isDark ? ColorManager.lightGrey : ColorManager.darkGrey),
            onPressed: _showMediaPicker,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Container(
              constraints: BoxConstraints(maxHeight: 120.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: TextField(
                controller: _controller,
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
            child: _hasText
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
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  final Duration duration;
  final bool isDark;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final String Function(Duration) formatDuration;

  const _RecordingBar({
    required this.duration,
    required this.isDark,
    required this.onSend,
    required this.onCancel,
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
                _PulsingDot(),
                SizedBox(width: 8.w),
                Text(
                  'Recording…  ${formatDuration(duration)}',
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
