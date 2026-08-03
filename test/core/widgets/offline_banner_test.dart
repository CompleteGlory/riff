import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/networks/connectivity_service.dart';
import 'package:riff/core/widgets/offline_banner.dart';

import '../../helpers/pump_app.dart';

/// See offline_banner_test.md for what this covers and why.
void main() {
  setUp(ConnectivityService.resetInstanceForTest);
  tearDown(ConnectivityService.resetInstanceForTest);

  Future<void> pumpBanner(WidgetTester tester) => pumpApp(
        tester,
        const OfflineBanner(
          child: Scaffold(body: Center(child: Text('app content'))),
        ),
      );

  Future<void> goOffline(WidgetTester tester) async {
    ConnectivityService.instance.probe = () async => false;
    await ConnectivityService.instance.checkNow();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Stops the offline backoff timer.
  ///
  /// While offline the service keeps a pending `Timer` to re-probe, and the
  /// test binding fails any test that ends with one outstanding — so a test
  /// that finishes offline has to stop it inside the test body. A `tearDown`
  /// is too late: the binding checks before user tear-downs run.
  Future<void> stopProbing() => ConnectivityService.instance.dispose();

  Future<void> goOnline(WidgetTester tester) async {
    ConnectivityService.instance.reportReachable();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('shows nothing while the connection is fine', (tester) async {
    await pumpBanner(tester);

    expect(find.text('app content'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
    expect(find.byIcon(Icons.wifi_rounded), findsNothing);
  });

  testWidgets('appears when the connection drops', (tester) async {
    await pumpBanner(tester);

    await goOffline(tester);

    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    // The app is still there underneath — the bar displaces it, it does not
    // replace it.
    expect(find.text('app content'), findsOneWidget);
    await stopProbing();
  });

  // Without the confirmation the bar just vanishes and the user is left
  // guessing whether anything actually reconnected.
  testWidgets('confirms recovery, then gets out of the way', (tester) async {
    await pumpBanner(tester);
    await goOffline(tester);

    await goOnline(tester);
    expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);

    await tester.pump(OfflineBanner.recoveryNoticeDuration);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.wifi_rounded), findsNothing);
    expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
  });

  testWidgets('the offline bar never covers the screen it sits above',
      (tester) async {
    await pumpBanner(tester);
    await goOffline(tester);

    final bar = tester.getRect(find.byIcon(Icons.wifi_off_rounded));
    final content = tester.getRect(find.text('app content'));
    expect(bar.bottom, lessThanOrEqualTo(content.top),
        reason: 'the bar pushes content down rather than overlapping it');
    await stopProbing();
  });
}
