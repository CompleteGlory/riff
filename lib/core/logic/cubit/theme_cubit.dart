import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  // First install (no saved preference yet) → follow the phone's mode.
  ThemeCubit() : super(ThemeMode.system);

  static const _key = 'app_theme_mode';

  /// Loads the saved preference. If the user has never chosen a mode, we keep
  /// [ThemeMode.system] so the app matches the phone's light/dark setting.
  Future<void> loadTheme() async {
    final saved = await SharedPrefHelper.getString(_key);
    emit(
      saved == 'dark'
          ? ThemeMode.dark
          : saved == 'light'
              ? ThemeMode.light
              : ThemeMode.system,
    );
  }

  /// Toggles between light and dark. [currentIsDark] is the effective brightness
  /// resolved by the UI (so it works even when we're currently on system mode),
  /// and the explicit choice is persisted for next launch.
  Future<void> toggleTheme(bool currentIsDark) async {
    final next = currentIsDark ? ThemeMode.light : ThemeMode.dark;
    await SharedPrefHelper.setData(
      _key,
      next == ThemeMode.dark ? 'dark' : 'light',
    );
    emit(next);
  }

  bool get isDark => state == ThemeMode.dark;
}
