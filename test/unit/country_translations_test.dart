import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/core/constants/country_database.dart';
import 'package:airwatch_mobile/core/l10n/country_translations.dart';

/// Verifies the locale-aware country search promised by the user
/// (Tunesien/Tunisie/Tunisia all resolve to TN). Pure logic — no
/// Flutter widgets, no network.
void main() {
  group('localizeCountry', () {
    test('English passthrough', () {
      expect(localizeCountry('Germany', 'en'), 'Germany');
      expect(localizeCountry('Tunisia', 'en'), 'Tunisia');
    });

    test('German translations', () {
      expect(localizeCountry('Germany', 'de'), 'Deutschland');
      expect(localizeCountry('France', 'de'), 'Frankreich');
      expect(localizeCountry('Tunisia', 'de'), 'Tunesien');
      expect(localizeCountry('UK', 'de'), 'Vereinigtes Königreich');
      expect(localizeCountry('Morocco', 'de'), 'Marokko');
    });

    test('French translations', () {
      expect(localizeCountry('Germany', 'fr'), 'Allemagne');
      expect(localizeCountry('France', 'fr'), 'France');
      expect(localizeCountry('Tunisia', 'fr'), 'Tunisie');
      expect(localizeCountry('United Kingdom', 'fr'), 'Royaume-Uni');
      expect(localizeCountry('Morocco', 'fr'), 'Maroc');
    });

    test('unknown country falls back to the input', () {
      expect(localizeCountry('Atlantis', 'de'), 'Atlantis');
    });
  });

  group('resolveCountryAlias (reverse lookup)', () {
    test('Tunesien / Tunisie / Tunisia all resolve to Tunisia', () {
      expect(resolveCountryAlias('Tunesien'), 'Tunisia');
      expect(resolveCountryAlias('Tunisie'), 'Tunisia');
      expect(resolveCountryAlias('Tunisia'), 'Tunisia');
    });

    test('case + diacritic insensitive', () {
      expect(resolveCountryAlias('TUNESIEN'), 'Tunisia');
      expect(resolveCountryAlias('  tunisie '), 'Tunisia');
      expect(resolveCountryAlias('Allemagne'), 'Germany');
      expect(
        resolveCountryAlias('Königreich Vereinigtes'),
        isNull,
        reason: 'word order matters — only known full names match',
      );
      expect(resolveCountryAlias('Vereinigtes Königreich'), 'United Kingdom');
      // Strips diacritics for the lookup so "österreich" works without ö.
      expect(resolveCountryAlias('Osterreich'), 'Austria');
    });

    test('unknown query returns null', () {
      expect(resolveCountryAlias(''), isNull);
      expect(resolveCountryAlias('xyz'), isNull);
    });

    test('Royaume-Uni → United Kingdom', () {
      expect(resolveCountryAlias('Royaume-Uni'), 'United Kingdom');
    });
  });

  group('countryNameMatches (substring across locales)', () {
    test('English substring', () {
      expect(countryNameMatches('Tunisia', 'tun'), isTrue);
      expect(countryNameMatches('Germany', 'germ'), isTrue);
    });

    test('German substring', () {
      expect(countryNameMatches('Tunisia', 'tunesi'), isTrue);
      expect(countryNameMatches('Germany', 'deutsch'), isTrue);
      expect(countryNameMatches('United Kingdom', 'königreich'), isTrue);
    });

    test('French substring', () {
      expect(countryNameMatches('Tunisia', 'tunisie'), isTrue);
      expect(countryNameMatches('Germany', 'allemag'), isTrue);
    });

    test('non-match returns false', () {
      expect(countryNameMatches('Tunisia', 'germany'), isFalse);
    });
  });

  group('CountryDatabase.find — locale fallback', () {
    test('finds TN when given Tunesien / Tunisie / Tunisia', () {
      expect(CountryDatabase.find('Tunesien')?.code, 'TN');
      expect(CountryDatabase.find('Tunisie')?.code, 'TN');
      expect(CountryDatabase.find('Tunisia')?.code, 'TN');
    });

    test('finds DE / FR / GB via German + French names', () {
      expect(CountryDatabase.find('Deutschland')?.code, 'DE');
      expect(CountryDatabase.find('Allemagne')?.code, 'DE');
      expect(CountryDatabase.find('Frankreich')?.code, 'FR');
      expect(CountryDatabase.find('Royaume-Uni')?.code, 'GB');
    });

    test('still finds via existing English aliases', () {
      expect(CountryDatabase.find('USA')?.code, 'US');
      expect(CountryDatabase.find('UK')?.code, 'GB');
      expect(CountryDatabase.find('England')?.code, 'GB');
    });

    test('unknown query returns null', () {
      expect(CountryDatabase.find('Atlantis'), isNull);
    });
  });

  group('CountryDatabase.search — picks up de/fr aliases', () {
    test('typing Tunesien finds Tunisia', () {
      final hits = CountryDatabase.search('Tunesien', limit: 5);
      expect(hits, isNotEmpty);
      expect(hits.first.code, 'TN');
    });

    test('typing Marokko finds Morocco', () {
      final hits = CountryDatabase.search('Marokko', limit: 5);
      expect(hits, isNotEmpty);
      expect(hits.first.code, 'MA');
    });

    test('typing Allemagne finds Germany', () {
      final hits = CountryDatabase.search('Allemagne', limit: 5);
      expect(hits, isNotEmpty);
      expect(hits.first.code, 'DE');
    });
  });
}
