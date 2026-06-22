import 'package:flutter/foundation.dart';

/// Global singleton for tracking video upload progress across the app.
///
/// Updated by [CreatePostCubit] during a multipart upload; listened to by
/// [UploadOverlay] in [RiffMaterialApp] so the bar remains visible even when
/// the user navigates away from the create-post screen.
class UploadProgressService {
  UploadProgressService._();
  static final UploadProgressService instance = UploadProgressService._();

  /// `null`  → no upload in progress (bar hidden)
  /// `0.0–1.0` → fraction of bytes sent (bar visible)
  final ValueNotifier<double?> uploadProgress = ValueNotifier(null);

  /// Whether the user has manually dismissed the bar for this upload.
  /// Reset to `false` automatically when a new upload starts or finishes.
  final ValueNotifier<bool> dismissed = ValueNotifier(false);

  void setProgress(double? progress) {
    if (progress == null) {
      // Upload finished — reset dismissed so the bar can show next time.
      dismissed.value = false;
    } else if (uploadProgress.value == null) {
      // New upload starting — un-dismiss any previous dismissal.
      dismissed.value = false;
    }
    uploadProgress.value = progress;
  }

  /// Hide the bar for the current upload without cancelling it.
  void dismiss() => dismissed.value = true;
}
