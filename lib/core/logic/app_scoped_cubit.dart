import 'package:flutter_bloc/flutter_bloc.dart';

/// Marks a cubit whose lifetime is the **app**, not a route.
///
/// GetIt singletons handed to `BlocProvider(create: ...)` get `close()`d when
/// that route pops, and a closed bloc can never emit again. Because `getIt`
/// keeps handing back the same dead instance, one bad provider poisons the
/// feature for the rest of the process — which is how "mark all as read
/// sometimes works, sometimes doesn't" and the frozen chat list happened: both
/// only broke *after* the user had opened, and backed out of, a screen that
/// provided the singleton with `create:` (the push-notification routes and the
/// Home route both did).
///
/// The call sites now use `BlocProvider.value`, but relying on every future
/// call site to remember that is how this bug came back twice. Cubits with this
/// mixin simply ignore `close()`; only [disposePermanently] really closes them.
///
/// Note for tests: `blocTest` and friends call `close()` at teardown, so a
/// stream matcher that expects `emitsDone` needs [disposePermanently] instead.
mixin AppScopedCubit<S> on BlocBase<S> {
  bool _allowClose = false;

  /// True once [disposePermanently] has been called — subclasses that override
  /// `close()` to release resources should check this before doing any work.
  bool get isPermanentlyClosing => _allowClose;

  /// Really closes the cubit. Call this only when the app itself is tearing
  /// the singleton down, never from a `BlocProvider`.
  Future<void> disposePermanently() {
    _allowClose = true;
    return close();
  }

  @override
  Future<void> close() {
    if (!_allowClose) return Future<void>.value();
    return super.close();
  }
}
