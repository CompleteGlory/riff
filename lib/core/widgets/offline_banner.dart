import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/networks/connectivity_service.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/generated/l10n.dart';

/// App-wide connection status bar.
///
/// Wraps the whole navigator (see `RiffMaterialApp.builder`) so the answer to
/// "is anything I'm looking at real?" is always one glance away, on every
/// screen, without each screen having to ask. A short "back online" bar
/// confirms recovery and then gets out of the way — without it the banner just
/// disappears and the user is left guessing whether it worked.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  /// How long the "back online" confirmation stays up.
  static const Duration recoveryNoticeDuration = Duration(seconds: 2);

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  StreamSubscription<bool>? _sub;
  Timer? _recoveryTimer;
  late bool _offline;
  bool _showRecovered = false;

  @override
  void initState() {
    super.initState();
    _offline = ConnectivityService.instance.isOffline;
    _sub = ConnectivityService.instance.onStatusChanged.listen(_onStatus);
  }

  void _onStatus(bool online) {
    if (!mounted) return;
    setState(() {
      _offline = !online;
      _showRecovered = online;
    });
    _recoveryTimer?.cancel();
    if (!online) return;
    _recoveryTimer = Timer(OfflineBanner.recoveryNoticeDuration, () {
      if (mounted) setState(() => _showRecovered = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _recoveryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showBar = _offline || _showRecovered;
    // Nothing to say — hand the app straight through, untouched.
    if (!showBar) return widget.child;

    // The bar displaces the app rather than floating over it. Overlaying looked
    // tidier but sat on top of every screen's AppBar, hiding the title and the
    // chat/notification actions exactly when the user most wants to see what
    // still works.
    final topInset = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            // Grow downward from the top edge (vertical axis → x is -1).
            alignment: const Alignment(-1, -1),
            child: child,
          ),
          child: _StatusBar(
            key: ValueKey(_offline),
            offline: _offline,
            topInset: topInset,
          ),
        ),
        // The bar has already consumed the status-bar inset, so the app below
        // must not pad for it a second time.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    super.key,
    required this.offline,
    required this.topInset,
  });

  final bool offline;

  /// Status-bar height, painted in the bar's colour so the notch area doesn't
  /// end up a mismatched strip above it.
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final background = offline ? const Color(0xFF3A3A3A) : const Color(0xFF2E7D32);

    return Material(
      color: background,
      child: Container(
        width: double.infinity,
        color: background,
        padding: EdgeInsets.fromLTRB(16.w, topInset + 7.h, 16.w, 7.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              offline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
              size: 14.r,
              color: Colors.white,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                offline
                    ? '${s.offlineBannerTitle} · ${s.offlineBannerSubtitle}'
                    : s.offlineBackOnline,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.font12Medium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline "this is saved content" strip for a screen that fell back to cache.
///
/// The global banner says the device is offline; this says *this list* is a
/// snapshot rather than the current truth, which is the part that actually
/// changes how the user should read it.
class OfflineCachedNotice extends StatelessWidget {
  const OfflineCachedNotice({super.key, this.savedAt});

  /// When the cached copy was written, if known.
  final DateTime? savedAt;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = savedAt == null
        ? s.offlineCachedNotice
        : s.offlineCachedNoticeWithTime(_relative(savedAt!));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded,
              size: 14.r, color: ColorManager.normalGrey),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyles.font12regular
                  .copyWith(color: ColorManager.normalGrey),
            ),
          ),
        ],
      ),
    );
  }

  static String _relative(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Full-screen state for "offline, and there is nothing cached to show".
class OfflineEmptyState extends StatelessWidget {
  const OfflineEmptyState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 44.r, color: ColorManager.normalGrey),
            SizedBox(height: 16.h),
            Text(s.offlineBannerTitle,
                style: TextStyles.font18Semibold, textAlign: TextAlign.center),
            SizedBox(height: 8.h),
            Text(
              s.offlineNothingSaved,
              textAlign: TextAlign.center,
              style: TextStyles.font14Medium
                  .copyWith(color: ColorManager.normalGrey, height: 1.5),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 24.h),
              TextButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded, size: 18.r),
                label: Text(s.retryBtn),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
