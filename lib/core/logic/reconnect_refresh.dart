import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/connectivity_service.dart';

/// Gives a cubit a "the connection came back — go get the real data" hook.
///
/// Falling back to cache is only half of a decent offline experience; the other
/// half is not making the user pull-to-refresh every screen once they walk back
/// into signal. Every cubit that can show cached content mixes this in and
/// re-fetches itself the moment [ConnectivityService] reports a recovery.
///
/// Only *transitions* are delivered (see [ConnectivityService.onStatusChanged]),
/// so a screen opened while online never fires this on arrival.
mixin ReconnectRefresh<S> on BlocBase<S> {
  StreamSubscription<bool>? _reconnectSub;

  /// Runs [onReconnect] each time connectivity is restored. Safe to call more
  /// than once — only the first call subscribes.
  void refreshOnReconnect(FutureOr<void> Function() onReconnect) {
    _reconnectSub ??=
        ConnectivityService.instance.onStatusChanged.listen((online) {
      if (online && !isClosed) onReconnect();
    });
  }

  /// Stops listening. Cubits with [AppScopedCubit] must call this from
  /// `disposePermanently`, since their `close()` is a no-op.
  void cancelReconnectRefresh() {
    _reconnectSub?.cancel();
    _reconnectSub = null;
  }

  @override
  Future<void> close() {
    cancelReconnectRefresh();
    return super.close();
  }
}
