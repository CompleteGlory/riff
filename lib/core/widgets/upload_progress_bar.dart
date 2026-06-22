import 'package:flutter/material.dart';

/// Upload notification bar shown at the top of the screen.
///
/// - Two-color track: [uploadedColor] for bytes already sent,
///   [remainingColor] for bytes still pending.
/// - Dismiss button (×) lets the user hide the bar without cancelling the upload.
class UploadProgressBar extends StatelessWidget {
  const UploadProgressBar({
    super.key,
    required this.progress,
    this.onDismiss,
    this.uploadedColor,
    this.remainingColor,
  });

  final double progress;
  final VoidCallback? onDismiss;
  final Color? uploadedColor;
  final Color? remainingColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uploaded = uploadedColor ?? theme.colorScheme.primary;
    final remaining = remainingColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Icon(Icons.upload_rounded, size: 16, color: uploaded),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploading… ${(progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 5,
                    child: LayoutBuilder(
                      builder: (_, constraints) {
                        final total = constraints.maxWidth;
                        return Stack(
                          children: [
                            // Remaining (background)
                            Container(width: total, color: remaining),
                            // Uploaded (foreground)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: total * progress,
                              color: uploaded,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Dismiss button — no tooltip: this widget renders above the
          // Navigator so no Overlay is available for tooltip popups.
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 16),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
