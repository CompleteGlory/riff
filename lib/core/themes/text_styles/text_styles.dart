import 'package:flutter/material.dart';
import 'font_weight_helper.dart';

/// Colors are intentionally null so widgets inherit the theme's onSurface color.
/// Dark mode = white text, Light mode = black text — automatically.
/// Call .copyWith(color: ...) anywhere you need an explicit override.
class TextStyles {

  static const TextStyle font13SemiBold = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 13,
    fontWeight: FontWeightHelper.semiBold,
  );

  static const TextStyle font20Bold = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 20,
    fontWeight: FontWeightHelper.bold,
  );

  static const TextStyle font20SemiBold = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 20,
    fontWeight: FontWeightHelper.semiBold,
  );

  static const TextStyle font28Bold = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 28,
    fontWeight: FontWeightHelper.extraBold,
  );

  static const TextStyle font45SemiBold = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 45,
    fontWeight: FontWeightHelper.semiBold,
  );

  static const TextStyle font16Medium = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 16,
    fontWeight: FontWeightHelper.medium,
  );

  static const TextStyle font15semiBold = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 15,
    fontWeight: FontWeightHelper.semiBold,
  );

  static const TextStyle font14regular = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 14,
    fontWeight: FontWeightHelper.regular,
  );

  static const TextStyle font14semiBold = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 14,
    fontWeight: FontWeightHelper.semiBold,
  );

  static const TextStyle font18Semibold = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 18,
    fontWeight: FontWeightHelper.semiBold,
  );

  static const TextStyle font14Medium = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 14,
    fontWeight: FontWeightHelper.medium,
  );

  static const TextStyle font12Medium = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 12,
    fontWeight: FontWeightHelper.medium,
  );

  static const TextStyle font12semiBold = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 12,
    fontWeight: FontWeightHelper.semiBold,
  );

  static const TextStyle font12regular = TextStyle(
    fontFamily: 'GeneralSans',
    fontSize: 12,
    fontWeight: FontWeightHelper.regular,
  );
}
