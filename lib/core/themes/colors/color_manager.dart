import 'package:flutter/material.dart';
import 'package:material_color_gen/material_color_gen.dart';

class ColorManager {
  static final MaterialColor primaryBlack = const Color(0xFF1A1A1A).toMaterialColor();
  static const Color black      = Color(0xFF1A1A1A);
  static const Color blackDeep  = Color(0xFF0D0D0D);
  static const Color blackCard  = Color(0xFF252525);
  static const Color accent     = Color(0xFFC6FF00); // electric lime — RC brand
  static const Color surface    = Color(0xFFF6F4F0); // warm off-white — RC brand
  static const Color lightBlack = Color(0xFF333333);
  static const Color darkGrey   = Color(0xFF4D4D4D);
  static const Color normalGrey = Color(0xFF808080);
  static const Color lightGrey  = Color(0xFFB3B3B3);
  static const Color lighterGrey = Color(0xFFE6E6E6);
  static const Color white      = Color(0xFFFFFFFF);
  static const Color green      = Color(0xFF0C9409);
  static const Color red        = Color(0xFFED1010);

  /// Colour for a pressable link inside body text.
  ///
  /// [accent] cannot be used on both themes: electric lime on the warm
  /// off-white [surface] is about 1.3:1, which is not a low-contrast link so
  /// much as an invisible one. The light variant is the same hue darkened
  /// until it clears WCAG AA for body text (~5:1 on [surface]), so a link
  /// still reads as Riff's colour rather than as a generic browser blue.
  static const Color linkOnDark  = accent;
  static const Color linkOnLight = Color(0xFF5B7300);

  static Color link(Brightness brightness) =>
      brightness == Brightness.dark ? linkOnDark : linkOnLight;
}
