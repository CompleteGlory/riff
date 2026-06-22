import 'package:flutter/material.dart';
import 'package:riff/core/services/upload_progress_service.dart';
import 'package:riff/core/widgets/upload_progress_bar.dart';

/// Wraps [child] in a [Stack] and overlays [UploadProgressBar] at the top of
/// the screen while an upload is in progress and not dismissed.
///
/// Plug this into [MaterialApp.builder] so it floats above every route.
class UploadOverlay extends StatelessWidget {
  const UploadOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final service = UploadProgressService.instance;
    return Stack(
      children: [
        child,
        AnimatedBuilder(
          // Rebuild whenever progress or dismissed changes.
          animation: Listenable.merge([service.uploadProgress, service.dismissed]),
          builder: (_, __) {
            final progress = service.uploadProgress.value;
            final isDismissed = service.dismissed.value;
            if (progress == null || isDismissed) return const SizedBox.shrink();
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: SafeArea(
                  bottom: false,
                  child: UploadProgressBar(
                    progress: progress,
                    onDismiss: service.dismiss,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
