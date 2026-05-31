import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/core/utils/text_normalizer.dart';

void main() {
  group('TextNormalizer.fixMojibake', () {
    group('single mojibake characters', () {
      test('fixes Latin-1 encoded è (Ã¨)', () {
        expect(TextNormalizer.fixMojibake('Ã¨'), 'è');
      });

      test('fixes Latin-1 encoded é (Ã©)', () {
        expect(TextNormalizer.fixMojibake('Ã©'), 'é');
      });

      test('fixes Latin-1 encoded ê (Ãª)', () {
        expect(TextNormalizer.fixMojibake('Ãª'), 'ê');
      });

      test('fixes Latin-1 encoded ë (Ã«)', () {
        expect(TextNormalizer.fixMojibake('Ã«'), 'ë');
      });

      test('fixes Latin-1 encoded à (Ã )', () {
        expect(TextNormalizer.fixMojibake('Ã '), 'à');
      });

      test('fixes Latin-1 encoded á (Ã¡)', () {
        expect(TextNormalizer.fixMojibake('Ã¡'), 'á');
      });

      test('fixes Latin-1 encoded ù (Ã¹)', () {
        expect(TextNormalizer.fixMojibake('Ã¹'), 'ù');
      });

      test('fixes Latin-1 encoded ç (Ã§)', () {
        expect(TextNormalizer.fixMojibake('Ã§'), 'ç');
      });

      test('fixes Turkish ş (ÅŸ)', () {
        expect(TextNormalizer.fixMojibake('ÅŸ'), 'ş');
      });

      test('fixes Turkish ğ (ÄŸ)', () {
        expect(TextNormalizer.fixMojibake('ÄŸ'), 'ğ');
      });

      test('fixes degree symbol (Â°)', () {
        expect(TextNormalizer.fixMojibake('Â°'), '°');
      });

      test('fixes control character (Â)', () {
        expect(TextNormalizer.fixMojibake('Â'), '');
      });
    });

    group('multiple mojibake characters', () {
      test('fixes multiple characters in a row', () {
        expect(
          TextNormalizer.fixMojibake('CafÃ© du MatinÃ©'),
          'Café du Matiné',
        );
      });

      test('fixes scattered mojibake throughout text', () {
        expect(
          TextNormalizer.fixMojibake('San JosÃ© to TokÃ´'),
          'San José to Tokô',
        );
      });

      test('fixes multiple mojibake characters side by side', () {
        expect(TextNormalizer.fixMojibake('CafÃ©Ã§on'), 'Caféçon');
      });

      test('fixes complex city names with multiple accents', () {
        expect(TextNormalizer.fixMojibake('MÃ¼nchen'), 'München');
      });

      test('fixes French place names', () {
        expect(TextNormalizer.fixMojibake('LÃ©nin MontÃ©'), 'Lénin Monté');
      });

      test('fixes text with capital and lowercase mojibake', () {
        expect(TextNormalizer.fixMojibake('Ã€ bientÃ´t'), 'À bientôt');
      });
    });

    group('edge cases', () {
      test('empty string returns empty', () {
        expect(TextNormalizer.fixMojibake(''), '');
      });

      test('string with no mojibake returns unchanged', () {
        expect(TextNormalizer.fixMojibake('Hello World'), 'Hello World');
      });

      test('ASCII-only text remains unchanged', () {
        expect(TextNormalizer.fixMojibake('San Francisco'), 'San Francisco');
      });

      test('already-correct UTF-8 text remains unchanged', () {
        expect(TextNormalizer.fixMojibake('Café'), 'Café');
      });

      test('mixed mojibake and correct text', () {
        expect(TextNormalizer.fixMojibake('Café vs CafÃ©'), 'Café vs Café');
      });

      test('text with numbers and mojibake', () {
        expect(
          TextNormalizer.fixMojibake('Route Â°51 CafÃ©'),
          'Route °51 Café',
        );
      });

      test('text with punctuation and mojibake', () {
        expect(TextNormalizer.fixMojibake('CafÃ©!? Yes!'), 'Café!? Yes!');
      });

      test('single space is preserved', () {
        expect(TextNormalizer.fixMojibake(' '), ' ');
      });

      test('whitespace with mojibake', () {
        expect(TextNormalizer.fixMojibake('  CafÃ©  '), '  Café  ');
      });
    });

    group('special characters from mojibake map', () {
      test('fixes uppercase À (Ã€)', () {
        expect(TextNormalizer.fixMojibake('Ã€'), 'À');
      });

      test('fixes uppercase É (Ã‰)', () {
        expect(TextNormalizer.fixMojibake('Ã‰'), 'É');
      });

      test('fixes uppercase Ä (Ã„)', () {
        expect(TextNormalizer.fixMojibake('Ã„'), 'Ä');
      });

      test('fixes uppercase Ö (Ã–)', () {
        expect(TextNormalizer.fixMojibake('Ã–'), 'Ö');
      });

      test('fixes uppercase Ü (Ãœ)', () {
        expect(TextNormalizer.fixMojibake('Ãœ'), 'Ü');
      });

      test('fixes uppercase Ç (Ã‡)', () {
        expect(TextNormalizer.fixMojibake('Ã‡'), 'Ç');
      });

      test('fixes uppercase Ş (Åž)', () {
        expect(TextNormalizer.fixMojibake('Åž'), 'Ş');
      });

      test('fixes œ ligature (Å")', () {
        expect(TextNormalizer.fixMojibake('Å"'), 'œ');
      });

      test('fixes š (Å¡)', () {
        expect(TextNormalizer.fixMojibake('Å¡'), 'š');
      });

      test('fixes ı without dot (Ä±)', () {
        expect(TextNormalizer.fixMojibake('Ä±'), 'ı');
      });

      test('fixes ñ (Ã±)', () {
        expect(TextNormalizer.fixMojibake('Ã±'), 'ñ');
      });

      test('fixes í (Ã­)', () {
        expect(TextNormalizer.fixMojibake('Ã­'), 'í');
      });

      test('fixes ï (Ã¯)', () {
        expect(TextNormalizer.fixMojibake('Ã¯'), 'ï');
      });

      test('fixes î (Ã®)', () {
        expect(TextNormalizer.fixMojibake('Ã®'), 'î');
      });

      test('fixes ò (Ã²)', () {
        expect(TextNormalizer.fixMojibake('Ã²'), 'ò');
      });

      test('fixes ó (Ã³)', () {
        expect(TextNormalizer.fixMojibake('Ã³'), 'ó');
      });

      test('fixes ö (Ã¶)', () {
        expect(TextNormalizer.fixMojibake('Ã¶'), 'ö');
      });

      test('fixes ô (Ã´)', () {
        expect(TextNormalizer.fixMojibake('Ã´'), 'ô');
      });

      test('fixes ã (Ã£)', () {
        expect(TextNormalizer.fixMojibake('Ã£'), 'ã');
      });

      test('fixes ä (Ã¤)', () {
        expect(TextNormalizer.fixMojibake('Ã¤'), 'ä');
      });

      test('fixes â (Ã¢)', () {
        expect(TextNormalizer.fixMojibake('Ã¢'), 'â');
      });

      test('fixes û (Ã»)', () {
        expect(TextNormalizer.fixMojibake('Ã»'), 'û');
      });

      test('fixes ü (Ã¼)', () {
        expect(TextNormalizer.fixMojibake('Ã¼'), 'ü');
      });
    });

    group('real-world scenarios', () {
      test('fixes airport/city names like São Paulo', () {
        expect(TextNormalizer.fixMojibake('SÃ£o Paulo'), 'São Paulo');
      });

      test('fixes airport names like Zürich', () {
        expect(TextNormalizer.fixMojibake('ZÃ¼rich'), 'Zürich');
      });

      test('fixes names like François', () {
        expect(TextNormalizer.fixMojibake('FranÃ§ois'), 'François');
      });

      test('fixes Montréal', () {
        expect(TextNormalizer.fixMojibake('MontrÃ©al'), 'Montréal');
      });

      test('fixes names like CÃ´te d\'Ivoire', () {
        expect(TextNormalizer.fixMojibake('CÃ´te d\'Ivoire'), 'Côte d\'Ivoire');
      });

      test('fixes Istanbul with Turkish characters', () {
        expect(TextNormalizer.fixMojibake('ÄŸstanbul'), 'ğstanbul');
      });

      test('fixes long text with multiple mojibake', () {
        expect(
          TextNormalizer.fixMojibake(
            'Flight from SÃ£o Paulo to ZÃ¼rich via Paris. Temperature 25Â°C',
          ),
          'Flight from São Paulo to Zürich via Paris. Temperature 25°C',
        );
      });

      test('preserves existing correct characters in mixed text', () {
        expect(
          TextNormalizer.fixMojibake('Café + CafÃ© = two cafés'),
          'Café + Café = two cafés',
        );
      });
    });

    group('replacement behavior', () {
      test('replaces mojibake with single correct character', () {
        final result = TextNormalizer.fixMojibake('test Ã© test');
        expect(result, 'test é test');
        expect(result.length, 'test é test'.length);
      });

      test('all replacements in one pass', () {
        const input = 'Ã© Ã  Ã§ Ã¹';
        final output = TextNormalizer.fixMojibake(input);
        expect(output, 'é à ç ù');
      });

      test('mojibake at start of string', () {
        expect(TextNormalizer.fixMojibake('Ã©cole'), 'école');
      });

      test('mojibake at end of string', () {
        expect(TextNormalizer.fixMojibake('cafÃ©'), 'café');
      });

      test('consecutive mojibake characters', () {
        expect(TextNormalizer.fixMojibake('tÃ©lÃ©phone'), 'téléphone');
      });
    });

    group('idempotence', () {
      test('applying fixMojibake twice gives same result as once', () {
        const input = 'CafÃ©';
        final once = TextNormalizer.fixMojibake(input);
        final twice = TextNormalizer.fixMojibake(once);
        expect(once, twice);
        expect(once, 'Café');
      });

      test('already-fixed text unchanged on second pass', () {
        const fixed = 'Café';
        final result = TextNormalizer.fixMojibake(fixed);
        expect(result, fixed);
      });
    });
  });
}
