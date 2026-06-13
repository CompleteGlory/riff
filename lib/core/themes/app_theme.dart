import 'package:flutter/material.dart';
import 'colors/color_manager.dart';

// ── Light Theme ───────────────────────────────────────────────────────────────
ThemeData lightTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'GeneralSans',
  colorScheme: ColorScheme.light(
    primary: ColorManager.black,
    onPrimary: ColorManager.white,
    secondary: ColorManager.accent,
    onSecondary: ColorManager.black,
    surface: ColorManager.surface,
    onSurface: ColorManager.black,
    surfaceContainerHighest: ColorManager.lighterGrey,
    error: ColorManager.red,
  ),
  scaffoldBackgroundColor: ColorManager.surface,
  primaryColor: ColorManager.black,
  primarySwatch: ColorManager.primaryBlack,
  appBarTheme: const AppBarTheme(
    backgroundColor: ColorManager.surface,
    foregroundColor: ColorManager.black,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontFamily: 'GeneralSans',
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: ColorManager.black,
    ),
    iconTheme: IconThemeData(color: ColorManager.black),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ColorManager.accent,
      foregroundColor: ColorManager.black,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontFamily: 'GeneralSans',
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ColorManager.black,
      side: const BorderSide(color: ColorManager.black, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontFamily: 'GeneralSans',
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ColorManager.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ColorManager.lighterGrey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ColorManager.lighterGrey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ColorManager.black, width: 1.5),
    ),
  ),
  cardTheme: const CardThemeData(
    color: ColorManager.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: ColorManager.white,
    surfaceTintColor: Colors.transparent,
  ),
  dividerColor: ColorManager.lighterGrey,
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: ColorManager.black,
  ),
  tabBarTheme: const TabBarThemeData(
    indicatorColor: ColorManager.black,
  ),
);

// ── Dark Theme ────────────────────────────────────────────────────────────────
ThemeData darkTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'GeneralSans',
  colorScheme: ColorScheme.dark(
    primary: ColorManager.accent,
    onPrimary: ColorManager.black,
    secondary: ColorManager.accent,
    onSecondary: ColorManager.black,
    surface: const Color(0xFF1A1A1A),
    onSurface: ColorManager.white,
    surfaceContainerHighest: const Color(0xFF252525),
    error: ColorManager.red,
  ),
  scaffoldBackgroundColor: const Color(0xFF141414),
  primaryColor: ColorManager.accent,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A1A1A),
    foregroundColor: ColorManager.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontFamily: 'GeneralSans',
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: ColorManager.white,
    ),
    iconTheme: IconThemeData(color: ColorManager.white),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ColorManager.accent,
      foregroundColor: ColorManager.black,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontFamily: 'GeneralSans',
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ColorManager.white,
      side: const BorderSide(color: Color(0xFF444444), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontFamily: 'GeneralSans',
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF252525),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ColorManager.accent, width: 1.5),
    ),
    hintStyle: const TextStyle(color: Color(0xFF666666)),
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF252525),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: Color(0xFF1A1A1A),
    surfaceTintColor: Colors.transparent,
  ),
  dividerColor: const Color(0xFF2A2A2A),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: ColorManager.accent,
  ),
  tabBarTheme: const TabBarThemeData(
    indicatorColor: ColorManager.accent,
  ),
);
