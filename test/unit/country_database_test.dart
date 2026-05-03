import 'package:flutter_test/flutter_test.dart';
import 'package:airwatch_mobile/core/constants/country_database.dart';

void main() {
  group('CountryDatabase', () {
    test('byCode resolves exact ISO code', () {
      expect(CountryDatabase.byCode('DE')?.name, 'Germany');
      expect(CountryDatabase.byCode('us')?.name, 'United States');
    });

    test('find resolves aliases', () {
      expect(CountryDatabase.find('USA')?.code, 'US');
      expect(CountryDatabase.find('uk')?.code, 'GB');
      expect(CountryDatabase.find('caribbean netherlands')?.code, 'BQ');
    });

    test('search prioritizes exact code and exact name matches', () {
      final byCode = CountryDatabase.search('DE');
      final byName = CountryDatabase.search('Germany');

      expect(byCode.first.code, 'DE');
      expect(byName.first.code, 'DE');
    });

    test('search supports prefix and alias matches', () {
      final united = CountryDatabase.search('uni');
      final caribbean = CountryDatabase.search('caribbean');

      expect(united.map((country) => country.code), contains('GB'));
      expect(united.map((country) => country.code), contains('US'));
      expect(caribbean.first.code, 'BQ');
    });

    test(
      'search applies limit and returns alphabetical defaults for empty query',
      () {
        final results = CountryDatabase.search('', limit: 5);

        expect(results, hasLength(5));
        expect(results.map((country) => country.code).toList(), [
          'AF',
          'AX',
          'AL',
          'DZ',
          'AS',
        ]);
      },
    );
  });
}
