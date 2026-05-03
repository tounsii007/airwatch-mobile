import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/core/l10n/city_translations.dart';

/// Mirrors the web app's `city-translations.test.ts`. Verifies that
/// the curated overrides map a sane set of key cities to the expected
/// translations and that the slang/historical names from the upstream
/// dataset are positively suppressed.
void main() {
  group('localizeCity — happy paths', () {
    test('English locale passes through unchanged', () {
      expect(localizeCity('Nice', 'en'), 'Nice');
      expect(localizeCity('Cologne', 'en'), 'Cologne');
    });

    test('translates German hubs', () {
      expect(localizeCity('Munich', 'de'), 'München');
      expect(localizeCity('Cologne', 'de'), 'Köln');
      expect(localizeCity('Vienna', 'de'), 'Wien');
      expect(localizeCity('Tokyo', 'de'), 'Tokio');
    });

    test('translates French hubs', () {
      expect(localizeCity('London', 'fr'), 'Londres');
      expect(localizeCity('Geneva', 'fr'), 'Genève');
      expect(localizeCity('Vienna', 'fr'), 'Vienne');
      expect(localizeCity('Athens', 'fr'), 'Athènes');
    });

    test('falls back to the original when no translation exists', () {
      expect(localizeCity('Atlantis', 'de'), 'Atlantis');
      expect(localizeCity('Nowhere', 'fr'), 'Nowhere');
    });

    test('tolerates casing and trailing whitespace', () {
      expect(localizeCity('nice', 'de'), 'Nizza');
      expect(localizeCity(' Munich ', 'de'), 'München');
    });

    test('empty input is returned unchanged', () {
      expect(localizeCity('', 'de'), '');
    });
  });

  group('Asian / ME / Africa coverage', () {
    test('major non-European hubs translate correctly', () {
      expect(localizeCity('Seoul', 'fr'), 'Séoul');
      expect(localizeCity('Singapore', 'de'), 'Singapur');
      expect(localizeCity('Dubai', 'fr'), 'Dubaï');
      expect(localizeCity('Beijing', 'de'), 'Peking');
      expect(localizeCity('Hong Kong', 'de'), 'Hongkong');
      expect(localizeCity('Mumbai', 'fr'), 'Bombay');
      expect(localizeCity('Cape Town', 'de'), 'Kapstadt');
      expect(localizeCity('Johannesburg', 'fr'), 'Johannesbourg');
      expect(localizeCity('Mexico City', 'de'), 'Mexiko-Stadt');
    });
  });

  group('historical / slang from upstream are NOT used', () {
    // These were the actual upstream failure modes we explicitly override:
    // Konstantinopel for Istanbul, Pantruche for Paris (slang), Jo'anna for
    // Johannesburg (slang), Reval for Tallinn (pre-1918), etc.
    test('overrides cover known upstream bugs', () {
      expect(localizeCity('Istanbul', 'de'), isNot('Konstantinopel'));
      expect(localizeCity('Paris', 'fr'), isNot('Pantruche'));
      expect(localizeCity('Johannesburg', 'fr'), 'Johannesbourg');
      expect(localizeCity('Bratislava', 'de'), 'Bratislava');
      expect(localizeCity('Zagreb', 'de'), 'Zagreb');
      expect(localizeCity('Tallinn', 'de'), 'Tallinn');
      expect(localizeCity('Almaty', 'de'), 'Almaty');
    });
  });

  group('compound airport labels', () {
    test('translates the city prefix only', () {
      expect(localizeCity('London Heathrow', 'fr'), 'Londres Heathrow');
      expect(localizeCity('Rome Fiumicino', 'de'), 'Rom Fiumicino');
      expect(localizeCity('Cologne Bonn', 'de'), 'Köln Bonn');
    });

    test('no-op when the prefix has no locale-specific form', () {
      expect(localizeCity('Paris CDG', 'de'), 'Paris CDG');
      expect(localizeCity('New York JFK', 'de'), 'New York JFK');
    });
  });

  group('resolveCityAlias', () {
    test('finds canonical English from German query', () {
      expect(resolveCityAlias('Nizza'), 'Nice');
      expect(resolveCityAlias('Köln'), 'Cologne');
      expect(resolveCityAlias('Wien'), 'Vienna');
      expect(resolveCityAlias('Tokio'), 'Tokyo');
    });

    test('finds canonical English from French query', () {
      expect(resolveCityAlias('Londres'), 'London');
      expect(resolveCityAlias('Genève'), 'Geneva');
      expect(resolveCityAlias('Vienne'), 'Vienna');
      expect(resolveCityAlias('Beyrouth'), 'Beirut');
    });

    test('English self-reference resolves', () {
      expect(resolveCityAlias('Nice'), 'Nice');
      expect(resolveCityAlias('Munich'), 'Munich');
    });

    test('diacritics are tolerated', () {
      expect(resolveCityAlias('Koln'), 'Cologne');
      expect(resolveCityAlias('Munchen'), 'Munich');
    });

    test('null/empty/unknown → null', () {
      expect(resolveCityAlias(''), isNull);
      expect(resolveCityAlias('Atlantis'), isNull);
    });
  });

  group('cityNameMatches', () {
    test('substring matches against English name', () {
      expect(cityNameMatches('Nice', 'nic'), isTrue);
      expect(cityNameMatches('Nice', 'NIC'), isTrue);
    });

    test('substring matches against any locale variant', () {
      expect(cityNameMatches('Nice', 'nizz'), isTrue);
      expect(cityNameMatches('Cologne', 'köln'), isTrue);
      expect(cityNameMatches('London', 'londr'), isTrue);
    });

    test('rejects unrelated queries', () {
      expect(cityNameMatches('Nice', 'Berlin'), isFalse);
      expect(cityNameMatches('Cologne', 'Paris'), isFalse);
    });

    test('compound prefixes work — typing "Köln" finds "Cologne Bonn"', () {
      expect(cityNameMatches('Cologne Bonn', 'köln'), isTrue);
      expect(cityNameMatches('Rome Fiumicino', 'rom'), isTrue);
      expect(cityNameMatches('London Heathrow', 'londr'), isTrue);
    });

    test('empty query yields false', () {
      expect(cityNameMatches('Nice', ''), isFalse);
    });

    test('falls back to plain substring for unknown cities', () {
      expect(cityNameMatches('SomeSmallTown', 'small'), isTrue);
      expect(cityNameMatches('SomeSmallTown', 'xyz'), isFalse);
    });
  });
}
