# `pump_app.dart`

Shared widget-test helper used by every file under `test/features/auth/login/UI/`. Pumps a widget
inside a `MaterialApp` configured the same way `RiffMaterialApp`
(`lib/core/widgets/riff_material_app.dart`) is in production:

- The generated `S.delegate` + the standard Flutter/Cupertino/Widgets localization delegates, so
  any widget calling `S.of(context)` works without extra setup per test.
- A `ScreenUtilInit` wrapper (same `designSize` as production), so `.w`/`.h`/`.r` extensions used
  throughout the login UI don't throw for being used before `ScreenUtil` is initialized.
- An optional `routes` map, so a test can stub out destinations the widget under test might
  navigate to (e.g. `/home`, `/signup`) without booting the real screens.

## Usage

```dart
await pumpApp(
  tester,
  BlocProvider<LoginCubit>.value(value: loginCubit, child: const LoginScreen()),
  routes: {'/home': (_) => const Scaffold(body: Text('HOME'))},
);
```

If you add a new widget test outside the login feature, prefer copying this pattern (or promoting
this helper to a more general location) rather than re-deriving the `MaterialApp` boilerplate.
