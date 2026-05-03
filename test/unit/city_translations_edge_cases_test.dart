import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/core/l10n/city_translations.dart';

void main() {
  group('localizeCity — basic locale resolution', () {
    test('en passes through unchanged', () {
      expect(localizeCity('Munich', 'en'), 'Munich');
      expect(localizeCity('Nice', 'en'), 'Nice');
    });

    test('de returns canonical German names from curated list', () {
      expect(localizeCity('Munich', 'de'), 'München');
      expect(localizeCity('Nice', 'de'), 'Nizza');
      expect(localizeCity('Cologne', 'de'), 'Köln');
      expect(localizeCity('Vienna', 'de'), 'Wien');
    });

    test('fr returns canonical French names from curated list', () {
      expect(localizeCity('Munich', 'fr'), 'Munich');
      expect(localizeCity('London', 'fr'), 'Londres');
      expect(localizeCity('Geneva', 'fr'), 'Genève');
    });

    test('unknown city returns the input as-is', () {
      expect(localizeCity('Atlantis', 'de'), 'Atlantis');
      expect(localizeCity('XYZ-City', 'fr'), 'XYZ-City');
    });
  });

  group('localizeCity — compound names', () {
    test('"London Heathrow" → "Londres Heathrow" in fr', () {
      expect(localizeCity('London Heathrow', 'fr'), 'Londres Heathrow');
    });

    test('"Rome Fiumicino" → "Rom Fiumicino" in de', () {
      expect(localizeCity('Rome Fiumicino', 'de'), 'Rom Fiumicino');
    });

    test(
      'compound where prefix translation EQUALS English — left untouched',
      () {
        // Lyon has the same form in en + de + fr.
        expect(localizeCity('Lyon Saint-Exupery', 'de'), 'Lyon Saint-Exupery');
      },
    );

    test('compound with unknown prefix returns input', () {
      expect(localizeCity('Atlantis Beach', 'de'), 'Atlantis Beach');
    });
  });

  group('cityNameMatches — substring + locale-aware', () {
    test('English substring on English name matches', () {
      expect(cityNameMatches('Nice Cote d\'Azur', 'nice'), isTrue);
      expect(cityNameMatches('London', 'lon'), isTrue);
    });

    test('German query matches the German variant', () {
      expect(cityNameMatches('Nice', 'Nizza'), isTrue);
      expect(cityNameMatches('Cologne', 'Köln'), isTrue);
      expect(cityNameMatches('Munich', 'München'), isTrue);
    });

    test('French query matches the French variant', () {
      expect(cityNameMatches('London', 'londres'), isTrue);
      expect(cityNameMatches('Geneva', 'Genève'), isTrue);
    });

    test('diacritic-insensitive — "Munchen" finds Munich', () {
      // Normalisation strips combining marks, so "Munchen" (no umlaut)
      // matches the German "München".
      expect(cityNameMatches('Munich', 'Munchen'), isTrue);
    });

    test('case-insensitive', () {
      expect(cityNameMatches('Nice', 'NIZZA'), isTrue);
      expect(cityNameMatches('Nice', 'nizza'), isTrue);
    });

    test('compound English city — substring on prefix still matches', () {
      // "London Heathrow" + query "Londres" should match via the
      // compound-prefix path.
      expect(cityNameMatches('London Heathrow', 'Londres'), isTrue);
    });

    test('empty query returns false (no spam matches)', () {
      expect(cityNameMatches('Nice', ''), isFalse);
      expect(cityNameMatches('Nice', '   '), isFalse);
    });

    test('non-substring returns false', () {
      expect(cityNameMatches('Nice', 'Berlin'), isFalse);
    });

    test('pure English-only fallback (city not in curated list)', () {
      // Unknown city — falls through to plain English substring match.
      expect(cityNameMatches('Faketown Heights', 'fake'), isTrue);
      expect(cityNameMatches('Faketown Heights', 'munich'), isFalse);
    });
  });

  group('resolveCityAlias — reverse lookup', () {
    test('Nizza → Nice', () {
      expect(resolveCityAlias('Nizza'), 'Nice');
    });

    test('Köln → Cologne', () {
      expect(resolveCityAlias('Köln'), 'Cologne');
    });

    test('Londres → London', () {
      expect(resolveCityAlias('Londres'), 'London');
    });

    test('case + diacritic insensitive', () {
      expect(resolveCityAlias('NIZZA'), 'Nice');
      expect(resolveCityAlias('nizza'), 'Nice');
      expect(resolveCityAlias('Munchen'), 'Munich');
    });

    test('English canonical also resolves to itself', () {
      expect(resolveCityAlias('Nice'), 'Nice');
      expect(resolveCityAlias('London'), 'London');
    });

    test('unknown query returns null', () {
      expect(resolveCityAlias('Atlantis'), isNull);
      expect(resolveCityAlias(''), isNull);
    });
  });

  group('Anti-regression: web-source data quality bugs', () {
    // The web's city-i18n curated layer fixes a few real-world data
    // bugs in the upstream GeoNames feed. These tests pin the fixes.
    test('Istanbul is NOT "Konstantinopel" in German', () {
      expect(localizeCity('Istanbul', 'de'), isNot('Konstantinopel'));
    });

    test('Mumbai stays Mumbai (NOT Bombay)', () {
      expect(localizeCity('Mumbai', 'en'), 'Mumbai');
    });

    test('Almaty stays Almaty (NOT "Werny")', () {
      expect(localizeCity('Almaty', 'de'), isNot('Werny'));
    });

    test('Zurich German is "Zürich" (NOT "Zuerich")', () {
      expect(localizeCity('Zurich', 'de'), 'Zürich');
    });

    test('Paris in fr is NOT "Pantruche" (slang)', () {
      expect(localizeCity('Paris', 'fr'), isNot('Pantruche'));
    });
  });
}
