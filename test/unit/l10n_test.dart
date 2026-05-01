import 'package:flutter_test/flutter_test.dart';
// `app_strings.dart` re-exports `AppStrings` from `strings_base.dart`,
// so a single import is enough for both `S` and `AppStrings`.
import 'package:airwatch_mobile/core/l10n/app_strings.dart';

void main() {
  group('Localization', () {
    test('S.of returns correct instance per language', () {
      expect(S.of(AppLanguage.en), isA<AppStrings>());
      expect(S.of(AppLanguage.de), isA<AppStrings>());
      expect(S.of(AppLanguage.fr), isA<AppStrings>());
    });

    test('English strings', () {
      final s = S.of(AppLanguage.en);
      expect(s.map, 'MAP');
      expect(s.search, 'SEARCH');
      expect(s.settings, 'SETTINGS');
      expect(s.altitude, 'ALTITUDE');
      expect(s.speed, 'SPEED');
      expect(s.departure, 'DEPARTURE');
      expect(s.arrival, 'ARRIVAL');
      expect(s.enRoute, 'EN ROUTE');
      expect(s.landed, 'LANDED');
      expect(s.delayed, 'DELAYED');
      expect(s.track, 'FOLLOW');
      expect(s.favorite, 'SAVE');
      expect(s.share, 'SHARE');
    });

    test('German strings', () {
      final s = S.of(AppLanguage.de);
      expect(s.map, 'KARTE');
      expect(s.search, 'SUCHE');
      expect(s.settings, 'EINSTELLUNGEN');
      expect(s.altitude, 'HÖHE');
      expect(s.speed, 'GESCHWINDIGKEIT');
      expect(s.departure, 'ABFLUG');
      expect(s.arrival, 'ANKUNFT');
      expect(s.enRoute, 'UNTERWEGS');
      expect(s.landed, 'GELANDET');
      expect(s.delayed, 'VERSPÄTET');
      expect(s.track, 'FOLGEN');
      expect(s.favorite, 'SPEICHERN');
      expect(s.share, 'TEILEN');
    });

    test('French strings', () {
      final s = S.of(AppLanguage.fr);
      expect(s.map, 'CARTE');
      expect(s.search, 'RECHERCHE');
      expect(s.settings, 'RÉGLAGES');
      expect(s.altitude, 'ALTITUDE');
      expect(s.speed, 'VITESSE');
      expect(s.departure, 'DÉPART');
      expect(s.arrival, 'ARRIVÉE');
      expect(s.enRoute, 'EN ROUTE');
      expect(s.landed, 'ATTERRI');
      expect(s.delayed, 'RETARDÉ');
      expect(s.track, 'SUIVRE');
      expect(s.favorite, 'ENREG.');
      expect(s.share, 'PARTAGER');
    });

    test('appName is same in all languages', () {
      expect(S.of(AppLanguage.en).appName, 'AirWatch');
      expect(S.of(AppLanguage.de).appName, 'AirWatch');
      expect(S.of(AppLanguage.fr).appName, 'AirWatch');
    });

    test('all navigation strings are non-empty in all languages', () {
      for (final lang in AppLanguage.values) {
        final s = S.of(lang);
        expect(s.map, isNotEmpty, reason: '${lang.name}.map');
        expect(s.search, isNotEmpty, reason: '${lang.name}.search');
        expect(s.airport, isNotEmpty, reason: '${lang.name}.airport');
        expect(s.favs, isNotEmpty, reason: '${lang.name}.favs');
        expect(s.settings, isNotEmpty, reason: '${lang.name}.settings');
      }
    });

    test('all status strings are non-empty in all languages', () {
      for (final lang in AppLanguage.values) {
        final s = S.of(lang);
        expect(s.enRoute, isNotEmpty, reason: '${lang.name}.enRoute');
        expect(s.landed, isNotEmpty, reason: '${lang.name}.landed');
        expect(s.scheduled, isNotEmpty, reason: '${lang.name}.scheduled');
        expect(s.delayed, isNotEmpty, reason: '${lang.name}.delayed');
        expect(s.onTime, isNotEmpty, reason: '${lang.name}.onTime');
        expect(s.onGround, isNotEmpty, reason: '${lang.name}.onGround');
        expect(s.airborne, isNotEmpty, reason: '${lang.name}.airborne');
      }
    });

    test('all flight detail strings are non-empty', () {
      for (final lang in AppLanguage.values) {
        final s = S.of(lang);
        expect(s.altitude, isNotEmpty);
        expect(s.speed, isNotEmpty);
        expect(s.heading, isNotEmpty);
        expect(s.departure, isNotEmpty);
        expect(s.arrival, isNotEmpty);
        expect(s.operatedBy, isNotEmpty);
      }
    });

    test('tagline exists in all languages', () {
      for (final lang in AppLanguage.values) {
        final s = S.of(lang);
        expect(s.tagline, isNotEmpty);
        expect(s.tagline.length, greaterThan(10));
      }
    });

    test('searchHint is different per language', () {
      final en = S.of(AppLanguage.en).searchHint;
      final de = S.of(AppLanguage.de).searchHint;
      final fr = S.of(AppLanguage.fr).searchHint;
      expect(en, isNot(equals(de)));
      expect(en, isNot(equals(fr)));
      expect(de, isNot(equals(fr)));
    });

    test('German uses correct special characters', () {
      final s = S.of(AppLanguage.de);
      expect(s.flights, contains('ü'));
      expect(s.delayed.toLowerCase(), contains('ä'));
    });

    test('French uses correct accents', () {
      final s = S.of(AppLanguage.fr);
      expect(s.operatedBy, contains('é'));
      expect(s.settings, contains('É'));
    });
  });
}
