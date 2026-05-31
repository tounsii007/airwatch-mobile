import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/utils/rtl.dart';

void main() {
  group('isRtl', () {
    test('returns true for Arabic', () {
      expect(isRtl(AppLanguage.ar), isTrue);
    });

    test('returns false for English', () {
      expect(isRtl(AppLanguage.en), isFalse);
    });

    test('returns false for German', () {
      expect(isRtl(AppLanguage.de), isFalse);
    });

    test('returns false for French', () {
      expect(isRtl(AppLanguage.fr), isFalse);
    });

    test('returns false for Spanish', () {
      expect(isRtl(AppLanguage.es), isFalse);
    });

    test('returns false for Italian', () {
      expect(isRtl(AppLanguage.it), isFalse);
    });

    test('returns false for Polish', () {
      expect(isRtl(AppLanguage.pl), isFalse);
    });

    test('returns false for Dutch', () {
      expect(isRtl(AppLanguage.nl), isFalse);
    });

    test('returns false for Turkish', () {
      expect(isRtl(AppLanguage.tr), isFalse);
    });

    test('only Arabic is RTL', () {
      const allLanguages = AppLanguage.values;
      final rtlCount = allLanguages.where(isRtl).length;
      expect(rtlCount, 1);
    });
  });

  group('textDirectionFor', () {
    test('returns TextDirection.rtl for Arabic', () {
      expect(textDirectionFor(AppLanguage.ar), equals(TextDirection.rtl));
    });

    test('returns TextDirection.ltr for English', () {
      expect(textDirectionFor(AppLanguage.en), equals(TextDirection.ltr));
    });

    test('returns TextDirection.ltr for German', () {
      expect(textDirectionFor(AppLanguage.de), equals(TextDirection.ltr));
    });

    test('returns TextDirection.ltr for French', () {
      expect(textDirectionFor(AppLanguage.fr), equals(TextDirection.ltr));
    });

    test('returns TextDirection.ltr for Spanish', () {
      expect(textDirectionFor(AppLanguage.es), equals(TextDirection.ltr));
    });

    test('returns TextDirection.ltr for Italian', () {
      expect(textDirectionFor(AppLanguage.it), equals(TextDirection.ltr));
    });

    test('returns TextDirection.ltr for Polish', () {
      expect(textDirectionFor(AppLanguage.pl), equals(TextDirection.ltr));
    });

    test('returns TextDirection.ltr for Dutch', () {
      expect(textDirectionFor(AppLanguage.nl), equals(TextDirection.ltr));
    });

    test('returns TextDirection.ltr for Turkish', () {
      expect(textDirectionFor(AppLanguage.tr), equals(TextDirection.ltr));
    });

    test('consistent with isRtl: returns rtl only when isRtl is true', () {
      for (final lang in AppLanguage.values) {
        final rtl = isRtl(lang);
        final direction = textDirectionFor(lang);
        if (rtl) {
          expect(direction, TextDirection.rtl);
        } else {
          expect(direction, TextDirection.ltr);
        }
      }
    });
  });

  group('rtlLanguages set', () {
    test('contains exactly one language', () {
      expect(rtlLanguages.length, 1);
    });

    test('contains Arabic', () {
      expect(rtlLanguages.contains(AppLanguage.ar), isTrue);
    });

    test('does not contain other languages', () {
      for (final lang in [
        AppLanguage.en,
        AppLanguage.de,
        AppLanguage.fr,
        AppLanguage.es,
        AppLanguage.it,
        AppLanguage.pl,
        AppLanguage.nl,
        AppLanguage.tr,
      ]) {
        expect(
          rtlLanguages.contains(lang),
          isFalse,
          reason: '$lang should not be in rtlLanguages',
        );
      }
    });
  });
}
