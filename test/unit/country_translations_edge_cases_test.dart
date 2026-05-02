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

    test('unknown country falls back to original input', () {
      expect(localizeCountry('Atlantis', 'de'), 'Atlantis');
      expect(localizeCountry('', 'fr'), '');
    });

    test('unknown locale falls back to original input', () {
      expect(localizeCountry('Germany', 'es'), 'Germany');
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
