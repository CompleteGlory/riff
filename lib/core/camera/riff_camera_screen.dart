import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:photo_manager/photo_manager.dart';

import 'package:riff/core/camera/camera_capture.dart';
import 'package:riff/core/camera/device_gallery.dart';
import 'package:riff/core/camera/gallery_panel.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/generated/l10n.dart';

/// The in-app camera: live preview, stills, and video with a hard duration cap.
///
/// Replaces handing the user off to the system camera app through
/// `image_picker`, which gave no control over how long a video could be, no
/// way to show the limit while recording, and a different look on every
/// device. Recording here stops itself at [maxVideoDuration], so a clip that
/// the server would reject can no longer be produced in the first place.
///
/// It is also the picker. There is no chooser before it: recent photos sit in
/// a strip above the shutter and "All" opens the full library, so reaching
/// something already on the phone costs one tap rather than a sheet, a
/// decision and then a system picker.
///
/// Push it and await the result:
/// ```dart
/// final shots = await RiffCameraScreen.open(context, maxVideoDuration: ...);
/// ```
/// Returns null when the user backs out or denies permission, and otherwise a
/// non-empty list — one item for a capture, up to [maxSelection] from the
/// gallery.
class RiffCameraScreen extends StatefulWidget {
  const RiffCameraScreen({
    super.key,
    required this.maxVideoDuration,
    this.allowVideo = true,
    this.maxSelection = 1,
  });

  /// Recording stops itself here. Callers pass their own ceiling — a chat clip
  /// is shorter than a post's — so the limit shown on screen is always the one
  /// that will actually be enforced.
  final Duration maxVideoDuration;

  /// False for surfaces that only accept a still, such as a profile or group
  /// photo. The mode switch is then hidden rather than shown-and-rejected.
  final bool allowVideo;

  /// How many gallery items may be taken at once. A post accepts up to ten,
  /// so asking for them one at a time would be worse than the multi-select
  /// picker this replaced. A capture is always a single item.
  final int maxSelection;

  static Future<List<CameraCapture>?> open(
    BuildContext context, {
    required Duration maxVideoDuration,
    bool allowVideo = true,
    int maxSelection = 1,
  }) {
    return Navigator.of(context).push<List<CameraCapture>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RiffCameraScreen(
          maxVideoDuration: maxVideoDuration,
          allowVideo: allowVideo,
          maxSelection: maxSelection,
        ),
      ),
    );
  }

  @override
  State<RiffCameraScreen> createState() => _RiffCameraScreenState();
}

class _RiffCameraScreenState extends State<RiffCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;

  /// Null until we know; distinguishes "still asking" from "denied".
  bool? _permitted;
  String? _fatalError;

  CameraMode _mode = CameraMode.photo;
  FlashMode _flash = FlashMode.off;
  bool _isRecording = false;
  bool _isBusy = false;

  /// Elapsed recording time, published on its own so the timer and the
  /// progress ring can repaint without rebuilding the preview underneath
  /// them. Rebuilding the whole tree ten times a second to move a countdown
  /// is the standard way a camera preview starts dropping frames.
  final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _elapsed.dispose();
    _controller?.dispose();
    super.dispose();
  }

  /// The camera is an exclusive resource: holding it while backgrounded keeps
  /// it from other apps and, on Android, the OS may revoke it and leave the
  /// controller pointing at nothing. Release on pause, rebuild on resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      if (_isRecording) unawaited(_stopRecording());
      controller.dispose();
      if (mounted) setState(() => _controller = null);
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_initController());
    }
  }

  // ── Setup ────────────────────────────────────────────────────────────────

  Future<void> _start() async {
    // Video needs the microphone too, and asking for both at once means one
    // interruption rather than two. A still-only camera never asks for audio
    // it will not record.
    final wanted = <Permission>[
      Permission.camera,
      if (widget.allowVideo) Permission.microphone,
    ];
    final results = await wanted.request();
    final granted = results.values.every((s) => s.isGranted || s.isLimited);

    if (!mounted) return;
    if (!granted) {
      setState(() => _permitted = false);
      return;
    }
    setState(() => _permitted = true);
    await _initController();
  }

  Future<void> _initController() async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _fatalError = S.of(context).cameraUnavailable);
        return;
      }

      final controller = CameraController(
        _cameras[_cameraIndex],
        // High rather than max: a 4K still from a modern sensor is tens of
        // megabytes, and everything here is bound for a 1080-wide feed.
        ResolutionPreset.high,
        enableAudio: widget.allowVideo,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(_flash);

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _fatalError = null;
      });
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _fatalError = e.description ?? S.of(context).cameraUnavailable);
      }
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _flip() async {
    if (_cameras.length < 2 || _isRecording || _isBusy) return;
    setState(() {
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
      _controller = null;
    });
    await _initController();
  }

  Future<void> _cycleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    const order = [FlashMode.off, FlashMode.auto, FlashMode.torch];
    final next = order[(order.indexOf(_flash) + 1) % order.length];
    try {
      await controller.setFlashMode(next);
      if (mounted) setState(() => _flash = next);
    } on CameraException {
      // Front cameras frequently have no flash. Saying nothing is right: the
      // control simply does not change, and an error toast for a hardware
      // feature the user did not ask about is noise.
    }
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || _isBusy || _isRecording) return;
    setState(() => _isBusy = true);
    try {
      final shot = await controller.takePicture();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context)
          .pop([CameraCapture(file: File(shot.path), isVideo: false)]);
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        _complain(e.description ?? S.of(context).cameraCaptureFailed);
      }
    }
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || _isBusy || _isRecording || !widget.allowVideo) {
      return;
    }
    try {
      await controller.startVideoRecording();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _elapsed.value = Duration.zero;
      setState(() => _isRecording = true);

      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        _elapsed.value += const Duration(milliseconds: 100);
        // The cap enforces itself. Leaving it to the user to stop in time is
        // what produced clips the server then refused.
        if (_elapsed.value >= widget.maxVideoDuration) unawaited(_stopRecording());
      });
    } on CameraException catch (e) {
      if (mounted) _complain(e.description ?? S.of(context).cameraCaptureFailed);
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !_isRecording) return;
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _isRecording = false;
      _isBusy = true;
    });
    try {
      final clip = await controller.stopVideoRecording();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context)
          .pop([CameraCapture(file: File(clip.path), isVideo: true)]);
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        _complain(e.description ?? S.of(context).cameraCaptureFailed);
      }
    }
  }

  /// Tap behaviour depends on the selected mode; holding always records, which
  /// is the gesture people arrive expecting.
  void _onShutterTap() {
    if (_isRecording) {
      unawaited(_stopRecording());
    } else if (_mode == CameraMode.video && widget.allowVideo) {
      unawaited(_startRecording());
    } else {
      unawaited(_takePhoto());
    }
  }

  /// Turns picked assets into files and returns them.
  ///
  /// An asset is not necessarily a file yet: an iCloud photo has to be
  /// downloaded first, and one can fail. Anything that cannot be resolved is
  /// dropped rather than returned as a broken path, and if nothing survives
  /// the user is told instead of being returned to an unchanged screen.
  Future<void> _useAssets(List<AssetEntity> assets) async {
    if (assets.isEmpty) return;
    setState(() => _isBusy = true);

    final resolved = <CameraCapture>[];
    for (final asset in assets) {
      final capture = await DeviceGallery.materialize(asset);
      if (capture != null) resolved.add(capture);
    }

    if (!mounted) return;
    if (resolved.isEmpty) {
      setState(() => _isBusy = false);
      _complain(S.of(context).galleryItemUnavailable);
      return;
    }
    Navigator.of(context).pop(resolved);
  }

  Future<void> _openFullGallery() async {
    final picked = await GalleryGridSheet.show(
      context,
      allowVideo: widget.allowVideo,
      maxSelection: widget.maxSelection,
    );
    if (picked != null && picked.isNotEmpty) await _useAssets(picked);
  }

  void _complain(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyles.font14Medium.copyWith(color: ColorManager.white)),
        backgroundColor: ColorManager.black,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // The camera chrome is deliberately dark in both themes: it sits over a
    // live preview whose colours are unknown and uncontrollable, so contrast
    // has to come from the scrims and pills below rather than from the theme.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreviewLayer(),
          if (_permitted == true && _fatalError == null) ...[
            _buildTopBar(),
            _buildBottomControls(),
          ] else
            _buildTopBar(),
        ],
      ),
    );
  }

  Widget _buildPreviewLayer() {
    if (_permitted == false) return _PermissionDenied(onOpenSettings: openAppSettings);
    if (_fatalError != null) return _CameraError(message: _fatalError!);

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: ColorManager.accent),
      );
    }

    // Fill the screen without distorting: the sensor's aspect ratio rarely
    // matches the phone's, and letting the preview stretch is the single most
    // obvious sign of a camera built in a hurry.
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Row(
          children: [
            _CircleButton(
              icon: Icons.close_rounded,
              label: S.of(context).cancelBtn,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const Spacer(),
            if (_isRecording) _RecordingPill(elapsed: _elapsed),
            const Spacer(),
            if (_permitted == true && _fatalError == null)
              _CircleButton(
                icon: _flashIcon,
                label: _flashLabel,
                // The active state has to be legible without colour alone, so
                // the icon changes shape as well as tint.
                tint: _flash == FlashMode.off ? null : ColorManager.accent,
                onTap: _cycleFlash,
              )
            else
              SizedBox(width: 48.w),
          ],
        ),
      ),
    );
  }

  IconData get _flashIcon => switch (_flash) {
        FlashMode.off => Icons.flash_off_rounded,
        FlashMode.auto => Icons.flash_auto_rounded,
        _ => Icons.flash_on_rounded,
      };

  String get _flashLabel => switch (_flash) {
        FlashMode.off => S.of(context).flashOff,
        FlashMode.auto => S.of(context).flashAuto,
        _ => S.of(context).flashOn,
      };

  Widget _buildBottomControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        // A scrim, not a solid bar: the controls must stay readable over a
        // bright sky or a white wall, which a transparent overlay does not
        // guarantee.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xCC000000)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: 16.h, top: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The gallery lives here rather than behind a sheet before the
                // camera: opening the camera is opening the picker.
                if (!_isRecording) ...[
                  GalleryStrip(
                    allowVideo: widget.allowVideo,
                    onPicked: (asset) => _useAssets([asset]),
                    onExpand: _openFullGallery,
                  ),
                  SizedBox(height: 12.h),
                ],
                if (widget.allowVideo && !_isRecording) _buildModeSwitch(),
                if (widget.allowVideo && !_isRecording) SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 56.w,
                      child: _cameras.length > 1 && !_isRecording
                          ? _CircleButton(
                              icon: Icons.cameraswitch_rounded,
                              label: S.of(context).switchCamera,
                              onTap: _flip,
                            )
                          : null,
                    ),
                    _Shutter(
                      isRecording: _isRecording,
                      isBusy: _isBusy,
                      mode: _mode,
                      elapsed: _elapsed,
                      maxDuration: widget.maxVideoDuration,
                      label: _isRecording
                          ? S.of(context).stopRecording
                          : _mode == CameraMode.video
                              ? S.of(context).recordVideo
                              : S.of(context).takePhoto,
                      onTap: _isBusy ? null : _onShutterTap,
                      onHoldStart: widget.allowVideo && !_isBusy
                          ? () {
                              if (!_isRecording) unawaited(_startRecording());
                            }
                          : null,
                      onHoldEnd: () {
                        if (_isRecording) unawaited(_stopRecording());
                      },
                    ),
                    SizedBox(width: 56.w),
                  ],
                ),
                SizedBox(height: 10.h),
                _buildHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHint() {
    final text = _isRecording
        ? S.of(context).releaseToStop
        : widget.allowVideo
            ? S.of(context).cameraHint
            : S.of(context).takePhoto;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyles.font12regular.copyWith(color: ColorManager.lighterGrey),
    );
  }

  /// Photo / Video as an explicit choice.
  ///
  /// The hold-to-record shortcut stays, but this is what makes video reachable
  /// with a single tap — an interface where the only route to a feature is a
  /// sustained press excludes people who cannot perform one.
  Widget _buildModeSwitch() {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChip(
            label: S.of(context).photoMode,
            selected: _mode == CameraMode.photo,
            onTap: () => setState(() => _mode = CameraMode.photo),
          ),
          _ModeChip(
            label: S.of(context).videoMode,
            selected: _mode == CameraMode.video,
            onTap: () => setState(() => _mode = CameraMode.video),
          ),
        ],
      ),
    );
  }
}

// ── Pieces ─────────────────────────────────────────────────────────────────

/// A 48dp tap target around a 24dp icon, on a scrim that keeps it legible over
/// an arbitrary preview.
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          // Meets the 48dp Android / 44pt iOS minimum even though the glyph
          // inside is 24dp.
          child: Container(
            width: 48.w,
            height: 48.w,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0x59000000),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24.r, color: tint ?? ColorManager.white),
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999.r),
        child: Container(
          constraints: BoxConstraints(minHeight: 40.h, minWidth: 88.w),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: selected ? ColorManager.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Text(
            label,
            style: TextStyles.font14Medium.copyWith(
              // Lime is a light colour: black on it clears 4.5:1, white does
              // not come close.
              color: selected ? ColorManager.black : ColorManager.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// The shutter, with a ring that fills as the recording approaches its limit.
class _Shutter extends StatelessWidget {
  const _Shutter({
    required this.isRecording,
    required this.isBusy,
    required this.mode,
    required this.elapsed,
    required this.maxDuration,
    required this.label,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final bool isRecording;
  final bool isBusy;
  final CameraMode mode;
  final ValueNotifier<Duration> elapsed;
  final Duration maxDuration;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    final size = 76.w;
    return Semantics(
      button: true,
      enabled: !isBusy,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: onHoldStart == null ? null : (_) => onHoldStart!(),
        onLongPressEnd: (_) => onHoldEnd(),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Only this subtree listens to the ticker, so the preview behind
              // it is not rebuilt ten times a second.
              ValueListenableBuilder<Duration>(
                valueListenable: elapsed,
                builder: (context, value, _) {
                  final progress = isRecording && maxDuration.inMilliseconds > 0
                      ? (value.inMilliseconds / maxDuration.inMilliseconds)
                          .clamp(0.0, 1.0)
                      : 0.0;
                  return SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: isRecording ? progress : 1,
                      strokeWidth: 4.r,
                      backgroundColor: const Color(0x40FFFFFF),
                      valueColor: AlwaysStoppedAnimation(
                        isRecording ? ColorManager.red : ColorManager.white,
                      ),
                    ),
                  );
                },
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: isRecording ? 30.w : 60.w,
                height: isRecording ? 30.w : 60.w,
                decoration: BoxDecoration(
                  color: isBusy
                      ? ColorManager.lightGrey
                      : isRecording
                          ? ColorManager.red
                          : mode == CameraMode.video
                              ? ColorManager.red
                              : ColorManager.white,
                  borderRadius:
                      BorderRadius.circular(isRecording ? 8.r : 999.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The red dot and elapsed time shown while recording.
class _RecordingPill extends StatelessWidget {
  const _RecordingPill({required this.elapsed});

  final ValueNotifier<Duration> elapsed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: elapsed,
      builder: (context, value, _) {
        final seconds = value.inSeconds;
        final text =
            '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
        return Semantics(
          liveRegion: true,
          label: S.of(context).recordingElapsed(text),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xCC000000),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: const BoxDecoration(
                    color: ColorManager.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  text,
                  style: TextStyles.font14Medium
                      .copyWith(color: ColorManager.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.onOpenSettings});

  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_outlined,
                size: 48.r, color: ColorManager.lightGrey),
            SizedBox(height: 16.h),
            Text(
              S.of(context).cameraPermissionNeeded,
              textAlign: TextAlign.center,
              style: TextStyles.font16Medium.copyWith(color: ColorManager.white),
            ),
            SizedBox(height: 24.h),
            // Denied twice on Android means the OS will not ask again, so the
            // only way forward is Settings. Saying "allow camera access"
            // without this button is a dead end.
            TextButton(
              onPressed: () => onOpenSettings(),
              style: TextButton.styleFrom(
                backgroundColor: ColorManager.accent,
                foregroundColor: ColorManager.black,
                minimumSize: Size(160.w, 48.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999.r)),
              ),
              child: Text(S.of(context).openSettings,
                  style: TextStyles.font14Medium
                      .copyWith(color: ColorManager.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyles.font16Medium.copyWith(color: ColorManager.white),
        ),
      ),
    );
  }
}
