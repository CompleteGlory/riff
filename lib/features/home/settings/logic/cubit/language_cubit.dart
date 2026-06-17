import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';

class LanguageCubit extends Cubit<Locale> {
  static const _prefKey = 'app_locale';

  LanguageCubit() : super(const Locale('en'));

  Future<void> loadLocale() async {
    final saved = await SharedPrefHelper.getString(_prefKey);
    if (saved is String && saved.isNotEmpty) {
      emit(Locale(saved));
    }
  }

  Future<void> setLocale(Locale locale) async {
    await SharedPrefHelper.setData(_prefKey, locale.languageCode);
    emit(locale);
  }

  bool get isArabic => state.languageCode == 'ar';
}
