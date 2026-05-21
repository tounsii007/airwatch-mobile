import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/core/constants/country_database.dart';
import 'package:airwatch_mobile/core/l10n/country_translations.dart';

void main() {
  group('localizeCountry — locale resolution', () {
    test('en passes the input through unchanged', () {
      expect(localizeCountry('Germany', 'en'), 'Germany');
      expect(localizeCountry('France', 'en'), 'France');
      expect(localizeCountry('Tunisia', 'en'), 'Tunisia');
    });

    test('de returns the German translation when available', () {
      expect(localizeCountry('Germany', 'de'), 'Deutschland');
      expect(localizeCountry('France', 'de'), 'Frankreich');
      expect(localizeCountry('Tunisia', 'de'), 'Tunesien');
      expect(localizeCountry('UAE', 'de'), 'Vereinigte Arabische Emirate');
    });

    test('fr returns the French translation when available', () {
      expect(localizeCountry('Germany', 'fr'), 'Allemagne');
      expect(localizeCountry('Tunisia', 'fr'), 'Tunisie');
      expect(localizeCountry('UK', 'fr'), 'Royaume-Uni');
    });

    test('es returns the Spanish translation when available', () {
      expect(localizeCountry('Germany', 'es'), 'Alemania');
      expect(localizeCountry('Spain', 'es'), 'España');
      expect(localizeCountry('Tunisia', 'es'), 'Túnez');
      expect(localizeCountry('UK', 'es'), 'Reino Unido');
    });

    test('it returns the Italian translation when available', () {
      expect(localizeCountry('Germany', 'it'), 'Germania');
      expect(localizeCountry('Spain', 'it'), 'Spagna');
      expect(localizeCountry('Tunisia', 'it'), 'Tunisia');
    });

    test('ar returns the Arabic translation when available', () {
      expect(localizeCountry('Germany', 'ar'), 'ألمانيا');
      expect(localizeCountry('Tunisia', 'ar'), 'تونس');
      expect(localizeCountry('UAE', 'ar'), 'الإمارات العربية المتحدة');
    });

    test('pl returns the Polish translation when available', () {
      expect(localizeCountry('Germany', 'pl'), 'Niemcy');
      expect(localizeCountry('UK', 'pl'), 'Wielka Brytania');
      expect(localizeCountry('Tunisia', 'pl'), 'Tunezja');
    });

    test('nl returns the Dutch translation when available', () {
      expect(localizeCountry('Germany', 'nl'), 'Duitsland');
      expect(localizeCountry('Netherlands', 'nl'), 'Nederland');
      expect(localizeCountry('Tunisia', 'nl'), 'Tunesië');
    });

    test('tr returns the Turkish translation when available', () {
      expect(localizeCountry('Germany', 'tr'), 'Almanya');
      expect(localizeCountry('Turkey', 'tr'), 'Türkiye');
      expect(localizeCountry('Tunisia', 'tr'), 'Tunus');
    });

    test('unknown country falls back to original input', () {
      expect(localizeCountry('Atlantis', 'de'), 'Atlantis');
      expect(localizeCountry('', 'fr'), '');
    });

    test('unknown locale falls back to original input', () {
      // "ja" (Japanese) is not one of the nine supported app locales.
      expect(localizeCountry('Germany', 'ja'), 'Germany');
    });
  });

  group('resolveCountryAlias — cross-locale reverse lookup', () {
    test('English variants normalise to canonical form', () {
      expect(resolveCountryAlias('Germany'), 'Germany');
      expect(resolveCountryAlias('germany'), 'Germany');
      expect(resolveCountryAlias('  GERMANY  '), 'Germany');
    });

    test('German query resolves to canonical English', () {
      expect(resolveCountryAlias('Tunesien'), 'Tunisia');
      expect(resolveCountryAlias('Deutschland'), 'Germany');
      expect(resolveCountryAlias('Frankreich'), 'France');
    });

    test('French query resolves to canonical English', () {
      expect(resolveCountryAlias('Tunisie'), 'Tunisia');
      expect(resolveCountryAlias('Allemagne'), 'Germany');
      expect(resolveCountryAlias('Royaume-Uni'), 'United Kingdom');
    });

    test('Spanish query resolves to canonical English', () {
      expect(resolveCountryAlias('Alemania'), 'Germany');
      expect(resolveCountryAlias('España'), 'Spain');
      expect(resolveCountryAlias('Túnez'), 'Tunisia');
    });

    test('Italian query resolves to canonical English', () {
      expect(resolveCountryAlias('Germania'), 'Germany');
      expect(resolveCountryAlias('Spagna'), 'Spain');
      expect(resolveCountryAlias('Italia'), 'Italy');
    });

    test('Arabic query resolves to canonical English', () {
      expect(resolveCountryAlias('ألمانيا'), 'Germany');
      expect(resolveCountryAlias('تونس'), 'Tunisia');
      expect(resolveCountryAlias('فرنسا'), 'France');
    });

    test('Polish query resolves to canonical English', () {
      expect(resolveCountryAlias('Niemcy'), 'Germany');
      expect(resolveCountryAlias('Tunezja'), 'Tunisia');
      expect(resolveCountryAlias('Francja'), 'France');
    });

    test('Dutch query resolves to canonical English', () {
      expect(resolveCountryAlias('Duitsland'), 'Germany');
      expect(resolveCountryAlias('Nederland'), 'Netherlands');
      expect(resolveCountryAlias('Frankrijk'), 'France');
    });

    test('Turkish query resolves to canonical English', () {
      expect(resolveCountryAlias('Almanya'), 'Germany');
      expect(resolveCountryAlias('Türkiye'), 'Turkey');
      expect(resolveCountryAlias('Tunus'), 'Tunisia');
    });

    test('diacritic-insensitive matching', () {
      // The reverse index is keyed on a diacritic-stripped form, so users
      // can type "Turkiye" / "Tunesien " / "Frankreich" interchangeably.
      expect(resolveCountryAlias('Turkiye'), 'Turkey');
      expect(resolveCountryAlias('  tunesien  '), 'Tunisia');
    });

    test('empty / unknown query yields null', () {
      expect(resolveCountryAlias(''), null);
      expect(resolveCountryAlias('Atlantis'), null);
      expect(resolveCountryAlias('xyz'), null);
    });
  });

  group('countryNameMatches — substring search across all 9 locales', () {
    test('English substring matches the canonical name', () {
      expect(countryNameMatches('Germany', 'german'), isTrue);
      expect(countryNameMatches('Tunisia', 'tun'), isTrue);
    });

    test('German substring matches via translation', () {
      expect(countryNameMatches('Morocco', 'Marok'), isTrue);
      expect(countryNameMatches('Tunisia', 'tunesien'), isTrue);
    });

    test('Polish substring matches via translation', () {
      expect(countryNameMatches('Germany', 'Niem'), isTrue);
      expect(countryNameMatches('Tunisia', 'Tunez'), isTrue);
    });

    test('Turkish substring matches via translation', () {
      expect(countryNameMatches('Germany', 'alman'), isTrue);
      expect(countryNameMatches('Tunisia', 'tunus'), isTrue);
    });

    test('non-matching query returns false', () {
      expect(countryNameMatches('Germany', 'spain'), isFalse);
      expect(countryNameMatches('Tunisia', ''), isFalse);
    });
  });

  group('CountryDatabase — search via aliases', () {
    test('case-insensitive English lookup', () {
      expect(CountryDatabase.codeOf('germany'), 'DE');
      expect(CountryDatabase.codeOf('GERMANY'), 'DE');
      expect(CountryDatabase.codeOf('Germany'), 'DE');
    });

    test('common alias works (USA → US)', () {
      expect(CountryDatabase.codeOf('USA'), 'US');
      expect(CountryDatabase.codeOf('uk'), 'GB');
      expect(CountryDatabase.codeOf('united kingdom'), 'GB');
    });

    test('whitespace + punctuation tolerated', () {
      expect(CountryDatabase.codeOf('  USA  '), 'US');
      expect(CountryDatabase.codeOf('U.S.A.'), 'US');
    });

    test('cross-locale ISO lookup — Polish → DE', () {
      // "Niemcy" (Polish for Germany) should resolve via the translation
      // alias and yield the canonical ISO code.
      expect(CountryDatabase.codeOf('Niemcy'), 'DE');
      expect(CountryDatabase.codeOf('Almanya'), 'DE');
    });

    test('cross-locale ISO lookup — Arabic → TN', () {
      expect(CountryDatabase.codeOf('تونس'), 'TN');
    });

    test('flag emoji generation for known 2-letter codes', () {
      expect(CountryDatabase.flagEmojiOf('DE'), '🇩🇪');
      expect(CountryDatabase.flagEmojiOf('FR'), '🇫🇷');
      expect(CountryDatabase.flagEmojiOf('TN'), '🇹🇳');
    });

    test('genuinely unknown code yields empty flag (no garbage rendering)', () {
      // XX is intentionally in the database as the "Unknown" placeholder
      // (so the UI never renders a literally-blank flag slot for legacy
      // data without a country). A truly bogus 2-letter code that isn't
      // in the list at all should fall through to "".
      expect(CountryDatabase.flagEmojiOf('ZZ'), '');
      expect(CountryDatabase.flagEmojiOf('Q1'), '');
    });

    test('flag asset path is lowercased', () {
      expect(CountryDatabase.flagAssetPathOf('DE'), 'assets/flags/4x3/de.svg');
      expect(CountryDatabase.flagAssetPathOf('GB'), 'assets/flags/4x3/gb.svg');
    });

    test('search returns sorted results — exact-match wins', () {
      // "Germany" should beat "Germany-something" if both existed.
      final results = CountryDatabase.search('Germany', limit: 5);
      expect(results.first.name, 'Germany');
    });

    test('search with too-broad query still respects limit', () {
      final results = CountryDatabase.search('a', limit: 3);
      expect(results.length, lessThanOrEqualTo(3));
    });

    test('empty / whitespace query returns top-N of full list', () {
      final results = CountryDatabase.search('', limit: 5);
      expect(results, hasLength(5));
      // Country 0 should be 'Afghanistan' alphabetically — verified
      // by the static const order in country_database.dart.
      expect(results.first.name, 'Afghanistan');
    });
  });

  group('Country flag — known regional gotchas', () {
    test('Korea aliases — "south korea" → KR, "north korea" → KP', () {
      expect(CountryDatabase.codeOf('south korea'), 'KR');
      expect(CountryDatabase.codeOf('north korea'), 'KP');
    });

    test('Russia + RU code resolved via alias', () {
      expect(CountryDatabase.codeOf('russia'), 'RU');
      expect(CountryDatabase.codeOf('Russia'), 'RU');
    });

    test('Ivory Coast → CI', () {
      expect(CountryDatabase.codeOf('ivory coast'), 'CI');
      expect(CountryDatabase.codeOf("Cote d'Ivoire"), 'CI');
    });

    test('Eswatini / Swaziland — both resolve to SZ', () {
      expect(CountryDatabase.codeOf('eswatini'), 'SZ');
      expect(CountryDatabase.codeOf('swaziland'), 'SZ');
    });
  });
}
