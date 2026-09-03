import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry ingest key for the Riff Flutter project.
///
/// A DSN is a *write-only* public identifier — it can only submit events, not
/// read them — so it lives in the source rather than in a build flag. Both
/// flavors report into the same project and are told apart by `environment`.
const String _sentryDsn =
    'https://8f0577f346cb5227ddfe9838d9f93a17@o4512019398983680.ingest.de.sentry.io/4512019421331536';

/// Boots Sentry and then runs [appRunner] inside its error zone.
///
/// Everything the app does at startup — Firebase, GetIt, the first frame —
/// belongs inside [appRunner], because `SentryFlutter.init` installs
/// `FlutterError.onError` and a guarded zone around it. Work done before this
/// call is invisible to Sentry if it throws.
Future<void> initSentryAndRun({
  required String environment,
  required double tracesSampleRate,
  required FutureOr<void> Function() appRunner,
}) async {
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;

      // Separates development crashes from real user ones in the dashboard.
      options.environment = environment;

      // SDK's own logging — noisy, and only useful while wiring this up.
      options.debug = kDebugMode;

      // Attaches request headers and the user's IP address. See
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = true;

      // Share of transactions kept for performance tracing. 1.0 in development
      // so every run is visible; sampled down in production so a busy day
      // doesn't burn the quota by lunchtime.
      options.tracesSampleRate = tracesSampleRate;
    },
    appRunner: appRunner,
  );
}
