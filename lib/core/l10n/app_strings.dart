import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'strings_base.dart';
import 'strings_en.dart';
import 'strings_de.dart';
import 'strings_fr.dart';
import 'strings_es.dart';
import 'strings_it.dart';
import 'strings_ar.dart';

// Re-export AppStrings so callers that already import this file for `S`
// get the actual interface type without a second import. Code that types
// `S` as a parameter is a bug — `S` is a static factory; the underlying
// instance type is `AppStrings`. The `_buildBody(AppStrings s, ...)`
// pattern across stats / airlines / cargo screens depends on this export.
export 'strings_base.dart' show AppStrings;

/// Supported app locales. Order is stable — the integer index lands in
/// SharedPreferences as `app_lang`, so adding a locale must always
/// happen at the END of the list to keep existing prefs valid.
enum AppLanguage { en, de, fr, es, it, ar }

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    _load();
    return AppLanguage.en;
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final idx = p.getInt('app_lang') ?? 0;
    state = AppLanguage.values[idx.clamp(0, AppLanguage.values.length - 1)];
  }

  Future<void> set(AppLanguage lang) async {
    state = lang;
    final p = await SharedPreferences.getInstance();
    await p.setInt('app_lang', lang.index);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(
  LanguageNotifier.new,
);

/// Get localized strings for a language.
/// Usage: S.of(AppLanguage.de).altitude → "HÖHE"
class S {
  static final _instances = <AppLanguage, AppStrings>{
    AppLanguage.en: StringsEn(),
    AppLanguage.de: StringsDe(),
    AppLanguage.fr: StringsFr(),
    AppLanguage.es: StringsEs(),
    AppLanguage.it: StringsIt(),
    AppLanguage.ar: StringsAr(),
  };

  static AppStrings of(AppLanguage lang) => _instances[lang] ?? StringsEn();

  static AppStrings ofLocale(Locale locale) => switch (locale.languageCode) {
    'de' => StringsDe(),
    'fr' => StringsFr(),
    'es' => StringsEs(),
    'it' => StringsIt(),
    'ar' => StringsAr(),
    _ => StringsEn(),
  };
}

Locale localeFromLanguage(AppLanguage lang) => switch (lang) {
  AppLanguage.de => const Locale('de'),
  AppLanguage.fr => const Locale('fr'),
  AppLanguage.es => const Locale('es'),
  AppLanguage.it => const Locale('it'),
  AppLanguage.ar => const Locale('ar'),
  AppLanguage.en => const Locale('en'),
};
