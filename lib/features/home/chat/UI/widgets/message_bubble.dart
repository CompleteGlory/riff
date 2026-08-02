import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/fullscsreen_image.dart';
import 'package:riff/generated/l10n.dart';
import 'package:riff/features/social_share/UI/widgets/link_preview_card.dart';
import 'package:riff/features/social_share/data/models/link_preview.dart';
import '../../../chat/data/models/chat_models.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSender;
  final bool showStatus; // show WA-style checkmarks on the last sent message
  final VoidCallback? onLongPress;

  /// Called when the user taps a message whose send failed.
  final VoidCallback? onRetry;

  /// Identifies the tap target that opens the fullscreen image viewer.
  ///
  /// Exposed for tests: `Image.file` doesn't resolve under the test binding, so
  /// a pending image bubble lays out zero-height and can't be tapped for real.
  static const imageTapKey = Key('chatImageBubble');

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSender = false,
    this.showStatus = false,
    this.onLongPress,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.isDeleted) {
      return _DeletedBubble(isMe: isMe, isDark: isDark);
    }

    // A message that hasn't reached the server yet is drawn faded, so "sent"
    // and "sending" are never the same picture. Anything else — clearing the
    // composer on an emit that may have gone nowhere — reads as delivered.
    final bubble = Opacity(
      opacity: message.isPending ? 0.55 : 1,
      child: _body(context, isDark),
    );

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: message.hasFailed ? onRetry : null,
      child: bubble,
    );
  }

  Widget _body(BuildContext context, bool isDark) {
    return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && showSender) ...[
              _Avatar(user: message.sender),
              SizedBox(width: 6.w),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe && showSender && message.sender != null)
                    Padding(
                      padding: EdgeInsets.only(left: 4.w, bottom: 2.h),
                      child: Text(
                        message.sender!.username ??
                            message.sender!.fullName ??
                            '',
                        style: TextStyles.font12semiBold
                            .copyWith(color: ColorManager.accent),
                      ),
                    ),
                  _BubbleContent(
                    message: message,
                    isMe: isMe,
                    isDark: isDark,
                    // A failed message's tap belongs to the retry handler on
                    // the whole bubble — opening the viewer instead would
                    // swallow it and leave no way to resend.
                    onImageTap:
                        message.hasFailed ? null : () => _openImage(context),
                  ),
                  SizedBox(height: 2.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fmt(message.createdAt),
                          style: TextStyles.font12regular.copyWith(
                            color: isDark
                                ? ColorManager.normalGrey
                                : ColorManager.darkGrey,
                            fontSize: 10,
                          ),
                        ),
                        if (isMe) ...[
                          SizedBox(width: 3.w),
                          _DeliveryIndicator(
                            message: message,
                            showStatus: showStatus,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  /// Opens the same fullscreen viewer post images use — pinch to zoom, tap to
  /// close. An image still uploading is read off disk, so it doesn't have to
  /// finish before it can be looked at.
  void _openImage(BuildContext context) {
    final url = message.mediaUrl;
    final local = message.localMediaPath;

    if (url != null && url.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FullScreenImage.single(imageUrl: url)),
      );
    } else if (local != null && local.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FullScreenImage.localFile(path: local)),
      );
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Delivery indicator ───────────────────────────────────────────────────────

/// The trailing marker on the sender's own messages.
///
/// Three distinct situations used to collapse into one grey check: still
/// uploading, failed outright, and genuinely sent. They now read differently —
/// a spinner, a tappable red warning, and the usual checkmarks.
class _DeliveryIndicator extends StatelessWidget {
  final ChatMessage message;
  final bool showStatus;

  const _DeliveryIndicator({required this.message, required this.showStatus});

  @override
  Widget build(BuildContext context) {
    if (message.isPending) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 9.r,
          height: 9.r,
          child: const CircularProgressIndicator(
            strokeWidth: 1.4,
            valueColor: AlwaysStoppedAnimation(ColorManager.normalGrey),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          S.of(context).messageSending,
          style: TextStyles.font12regular
              .copyWith(color: ColorManager.normalGrey, fontSize: 10),
        ),
      ]);
    }

    if (message.hasFailed) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded, size: 12.r, color: ColorManager.red),
        SizedBox(width: 4.w),
        Text(
          '${S.of(context).messageFailed} · ${S.of(context).messageRetrySend}',
          style: TextStyles.font12regular
              .copyWith(color: ColorManager.red, fontSize: 10),
        ),
      ]);
    }

    if (!showStatus) return const SizedBox.shrink();
    return _StatusIcon(status: message.status);
  }
}

// ─── WhatsApp-style checkmarks ────────────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  final MessageStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sent:
        return Icon(Icons.done_rounded, size: 14, color: ColorManager.normalGrey);
      case MessageStatus.delivered:
        return Icon(Icons.done_all_rounded, size: 14, color: ColorManager.normalGrey);
      case MessageStatus.read:
        return Icon(Icons.done_all_rounded, size: 14, color: Colors.green);
    }
  }
}

// ─── Content dispatcher ───────────────────────────────────────────────────────

class _BubbleContent extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isDark;

  /// Opens the fullscreen viewer. Null when the tap belongs to something else.
  final VoidCallback? onImageTap;

  const _BubbleContent({
    required this.message,
    required this.isMe,
    required this.isDark,
    this.onImageTap,
  });

  Color get _bg => isMe
      ? ColorManager.accent
      : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0));

  Color get _fg =>
      isMe ? ColorManager.black : (isDark ? ColorManager.white : ColorManager.black);

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
      case MessageType.link:
        return _TextBubble(text: message.content ?? '', bg: _bg, fg: _fg);
      case MessageType.image:
        return _ImageBubble(
          url: message.mediaUrl ?? '',
          // While the upload is in flight there is no remote URL yet — show the
          // file the user picked so the bubble isn't an empty grey box.
          localPath: message.localMediaPath,
          bg: _bg,
          onTap: onImageTap,
        );
      case MessageType.video:
        return _VideoBubble(url: message.mediaUrl ?? '', bg: _bg);
      case MessageType.audio:
        return _AudioBubble(
          url: message.mediaUrl ?? '',
          localPath: message.localMediaPath,
          duration: message.duration ?? 0,
          bg: _bg,
          fg: _fg,
        );
      case MessageType.file:
        return _FileBubble(
            fileName: message.fileName ?? 'File', bg: _bg, fg: _fg);
    }
  }
}

// ─── Text ─────────────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _TextBubble({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    final previewUrl = LinkPreview.extractFirst(text);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 0.72.sw),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(18.r)),
            child: Text(text, style: TextStyles.font14regular.copyWith(color: fg)),
          ),
          if (previewUrl != null)
            LinkPreviewCard(url: previewUrl, compact: true),
        ],
      ),
    );
  }
}

// ─── Image ────────────────────────────────────────────────────────────────────

class _ImageBubble extends StatelessWidget {
  final String url;
  final String? localPath;
  final Color bg;
  final VoidCallback? onTap;
  const _ImageBubble({
    required this.url,
    required this.bg,
    this.localPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        key: MessageBubble.imageTapKey,
        onTap: onTap,
        child: _thumbnail(),
      );

  Widget _thumbnail() {
    final local = localPath;
    if (url.isEmpty && local != null && local.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Image.file(
          File(local),
          width: 0.65.sw,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 0.65.sw,
            height: 180.h,
            color: bg,
            child: const Icon(Icons.image_outlined,
                color: ColorManager.normalGrey),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Image.network(
        url,
        width: 0.65.sw,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          final pct = progress.expectedTotalBytes != null
              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
              : null;
          return Container(
            width: 0.65.sw,
            height: 200.h,
            color: bg,
            child: Center(
              child: CircularProgressIndicator(
                value: pct,
                strokeWidth: 2.5,
                valueColor: const AlwaysStoppedAnimation(ColorManager.accent),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          width: 0.65.sw,
          height: 180.h,
          color: bg,
          child: const Icon(Icons.broken_image_outlined,
              color: ColorManager.normalGrey),
        ),
      ),
    );
  }
}

// ─── Video ────────────────────────────────────────────────────────────────────

class _VideoBubble extends StatelessWidget {
  final String url;
  final Color bg;
  const _VideoBubble({required this.url, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.65.sw,
      height: 200.h,
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16.r)),
      child: Stack(alignment: Alignment.center, children: [
        const Icon(Icons.play_circle_fill_rounded,
            size: 52, color: Colors.white70),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6)),
            child: const Text('VIDEO',
                style: TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ),
      ]),
    );
  }
}

// ─── Audio player bubble ──────────────────────────────────────────────────────

class _AudioBubble extends StatefulWidget {
  final String url;
  final String? localPath;
  final int duration;
  final Color bg;
  final Color fg;

  const _AudioBubble({
    required this.url,
    required this.duration,
    required this.bg,
    required this.fg,
    this.localPath,
  });

  /// Whether there is anything playable — a remote URL, or the local recording
  /// while it is still uploading.
  bool get hasSource =>
      url.isNotEmpty || (localPath != null && localPath!.isNotEmpty);

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  late final AudioPlayer _player;
  PlayerState _pState = PlayerState.stopped;
  Duration _pos = Duration.zero;
  Duration _total = Duration.zero;
  StreamSubscription? _stateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _total = Duration(seconds: widget.duration);

    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _pState = s);
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _pos = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_pState == PlayerState.playing) {
      await _player.pause();
    } else {
      if (_pState == PlayerState.completed) {
        await _player.seek(Duration.zero);
      }
      if (widget.url.isNotEmpty) {
        await _player.play(UrlSource(widget.url));
      } else if (widget.localPath != null && widget.localPath!.isNotEmpty) {
        await _player.play(DeviceFileSource(widget.localPath!));
      }
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final playing = _pState == PlayerState.playing;
    final totalMs = _total.inMilliseconds;
    final progress =
        totalMs > 0 ? (_pos.inMilliseconds / totalMs).clamp(0.0, 1.0) : 0.0;

    return Container(
      constraints: BoxConstraints(maxWidth: 0.72.sw),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
          color: widget.bg, borderRadius: BorderRadius.circular(18.r)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.fg.withValues(alpha: 0.12),
            ),
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 22,
              color: widget.fg,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: widget.fg,
                  inactiveTrackColor: widget.fg.withValues(alpha: 0.25),
                  thumbColor: widget.fg,
                  overlayColor: widget.fg.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: progress.toDouble(),
                  onChanged: !widget.hasSource
                      ? null
                      : (v) {
                          final ms = (v * totalMs).round();
                          _player.seek(Duration(milliseconds: ms));
                        },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_pos),
                        style: TextStyles.font12regular.copyWith(
                            color: widget.fg.withValues(alpha: 0.7),
                            fontSize: 10)),
                    Text(_fmt(_total),
                        style: TextStyles.font12regular.copyWith(
                            color: widget.fg.withValues(alpha: 0.7),
                            fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── File ─────────────────────────────────────────────────────────────────────

class _FileBubble extends StatelessWidget {
  final String fileName;
  final Color bg;
  final Color fg;
  const _FileBubble(
      {required this.fileName, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 0.72.sw),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18.r)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.attach_file_rounded, size: 20, color: fg),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(fileName,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.font14Medium.copyWith(color: fg)),
        ),
      ]),
    );
  }
}

// ─── Deleted ──────────────────────────────────────────────────────────────────

class _DeletedBubble extends StatelessWidget {
  final bool isMe;
  final bool isDark;
  const _DeletedBubble({required this.isMe, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 2.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
              color: isDark
                  ? const Color(0xFF444444)
                  : const Color(0xFFDDDDDD)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.do_not_disturb_on_outlined,
              size: 14,
              color: isDark ? ColorManager.normalGrey : ColorManager.darkGrey),
          SizedBox(width: 6.w),
          Text('Message deleted',
              style: TextStyles.font14regular.copyWith(
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? ColorManager.normalGrey
                      : ColorManager.darkGrey)),
        ]),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final MessageSender? user;
  const _Avatar({this.user});

  @override
  Widget build(BuildContext context) {
    final url = user?.profileImageUrl;
    return CircleAvatar(
      radius: 14.r,
      backgroundColor: ColorManager.lightBlack,
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null
          ? Text(
              (user?.username ?? user?.fullName ?? '?')
                  .substring(0, 1)
                  .toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            )
          : null,
    );
  }
}
