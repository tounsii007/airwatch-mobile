import 'package:airwatch_mobile/core/utils/metar_decode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodeMetar', () {
    test('parses a typical US METAR end-to-end', () {
      final r = decodeMetar(
        'METAR KSFO 101455Z 28012KT 10SM FEW015 SCT020 BKN200 17/12 A3001',
      );
      expect(r.station, 'KSFO');
      expect(r.observed, '10 14:55Z');
      expect(r.wind?.direction, 280);
      expect(r.wind?.speed, 12);
      expect(r.wind?.unit, 'KT');
      expect(r.wind?.gust, isNull);
      expect(r.visibility?.value, 10);
      expect(r.visibility?.unit, VisibilityUnit.sm);
      expect(r.cloudLayers.length, 3);
      expect(r.cloudLayers[0].cover, 'FEW');
      expect(r.cloudLayers[0].baseFt, 1500);
      expect(r.cloudLayers[2].cover, 'BKN');
      expect(r.cloudLayers[2].baseFt, 20000);
      expect(r.temperature.tempC, 17);
      expect(r.temperature.dewC, 12);
      expect(r.altimeter.inHg, closeTo(30.01, 0.001));
    });

    test('parses negative temperatures with M prefix', () {
      final r = decodeMetar('EFHK 101220Z 09008KT 9999 -SN OVC008 M03/M05 Q1013');
      expect(r.temperature.tempC, -3);
      expect(r.temperature.dewC, -5);
      expect(r.altimeter.hPa, 1013);
      expect(r.cloudLayers.single.cover, 'OVC');
      expect(r.cloudLayers.single.baseFt, 800);
    });

    test('treats VRB as variable wind, no direction', () {
      final r = decodeMetar('LFPG 101430Z VRB02KT 9999 NSC 22/14 Q1018');
      expect(r.wind?.variable, true);
      expect(r.wind?.direction, isNull);
      expect(r.wind?.speed, 2);
    });

    test('CAVOK collapses visibility + cloud cover into one token', () {
      final r = decodeMetar('LIRF 101220Z 18005KT CAVOK 28/16 Q1019');
      expect(r.visibility?.unit, VisibilityUnit.cavok);
      expect(r.cloudLayers.length, 1);
      expect(r.cloudLayers.single.cover, 'CAVOK');
    });

    test('decodes phenomenon stack like TSRA with intensity prefix', () {
      final r = decodeMetar('KORD 101455Z 24015G25KT 4SM +TSRA BKN025CB 21/19 A2978');
      expect(r.wind?.gust, 25);
      expect(r.phenomena.length, 2);
      expect(r.phenomena[0].intensity, '+');
      expect(r.phenomena[0].code, 'TS');
      expect(r.phenomena[1].code, 'RA');
      expect(r.cloudLayers.single.type, 'CB');
    });

    test('metric visibility 9999 maps to "≥10"', () {
      final r = decodeMetar('EDDF 101220Z 27010KT 9999 FEW040 23/12 Q1018');
      expect(r.visibility?.value, '≥10');
      expect(r.visibility?.unit, VisibilityUnit.m);
    });

    test('preserves remarks block as a single unknown blob', () {
      final r = decodeMetar('KSFO 101455Z 28012KT 10SM CLR 17/12 A3001 RMK AO2 SLP161');
      expect(r.unknown.any((u) => u.startsWith('RMK ')), isTrue);
    });
  });

  group('decodeTaf', () {
    test('walks header + FM/TEMPO windows', () {
      final r = decodeTaf(
        'TAF KSFO 101130Z 1012/1112 28010KT P6SM SKC '
        'FM101800 30015KT P6SM FEW020 '
        'TEMPO 1102/1106 BKN015',
      );
      expect(r.station, 'KSFO');
      expect(r.issued, '101130Z');
      expect(r.validFrom, '1012');
      expect(r.validTo, '1112');
      expect(r.windows.length, 3);
      expect(r.windows[0].label, 'INITIAL');
      expect(r.windows[1].label, 'FM');
      expect(r.windows[1].when, '101800');
      expect(r.windows[1].conditions.wind?.direction, 300);
      expect(r.windows[2].label, 'TEMPO');
      expect(r.windows[2].when, '1102/1106');
    });
  });

  group('phenomenonText', () {
    test('formats intensity prefixes', () {
      expect(
        phenomenonText(const DecodedPhenomenon(intensity: '-', code: 'RA')),
        'light rain',
      );
      expect(
        phenomenonText(const DecodedPhenomenon(intensity: '+', code: 'TS')),
        'heavy thunderstorm',
      );
      expect(
        phenomenonText(const DecodedPhenomenon(intensity: 'VC', code: 'FG')),
        'in vicinity: fog',
      );
      expect(
        phenomenonText(const DecodedPhenomenon(intensity: null, code: 'BR')),
        'mist',
      );
    });
  });
}
