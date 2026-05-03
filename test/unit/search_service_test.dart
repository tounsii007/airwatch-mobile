import 'package:flutter_test/flutter_test.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/search/data/models/search_models.dart';
import 'package:airwatch_mobile/features/search/data/services/search_service.dart';

void main() {
  group('SearchService', () {
    test('returns country results from local database', () async {
      final service = SearchService();

      final results = await service.search('Germany', liveAircraft: const {});

      expect(
        results.any((item) => item.type == SearchResultType.country),
        isTrue,
      );
      expect(
        results
            .where((item) => item.type == SearchResultType.country)
            .first
            .title,
        'Germany',
      );
    });

    test('matches live aircraft by country code from local database', () async {
      final service = SearchService();
      final aircraft = AircraftState(
        icao24: '3c664e',
        callsign: 'DLH123',
        originCountry: 'Germany',
        longitude: 8.57,
        latitude: 50.03,
        baroAltitude: 10000,
        velocity: 230,
        trueTrack: 180,
      );

      final results = await service.search(
        'DE',
        liveAircraft: {'3c664e': aircraft},
      );

      expect(
        results.any(
          (item) =>
              item.type == SearchResultType.liveAircraft &&
              item.aircraft?.callsign == 'DLH123',
        ),
        isTrue,
      );
    });

    test('prioritizes exact live callsign matches', () async {
      final service = SearchService();
      final aircraft = AircraftState(
        icao24: '3c664e',
        callsign: 'DLH123',
        originCountry: 'Germany',
        longitude: 8.57,
        latitude: 50.03,
        baroAltitude: 10000,
        velocity: 230,
        trueTrack: 180,
      );

      final results = await service.search(
        'DLH123',
        liveAircraft: {'3c664e': aircraft},
      );

      expect(results.first.type, SearchResultType.liveAircraft);
      expect(results.first.title, 'LH123');
      expect(results.first.aircraft?.callsign, 'DLH123');
    });

    test('matches live aircraft by ICAO24 when callsign is missing', () async {
      final service = SearchService();
      final aircraft = AircraftState(
        icao24: 'ABC123',
        originCountry: 'France',
        longitude: 2.55,
        latitude: 49.01,
        baroAltitude: 8000,
        velocity: 200,
        trueTrack: 90,
      );

      final results = await service.search(
        'ABC123',
        liveAircraft: {'ABC123': aircraft},
      );

      expect(results.first.type, SearchResultType.liveAircraft);
      expect(results.first.title, 'ABC123');
    });

    test(
      'globally ranks exact live flight matches before other result types',
      () async {
        final service = SearchService();
        final aircraft = AircraftState(
          icao24: '3c664e',
          callsign: 'DLH123',
          originCountry: 'Germany',
          longitude: 8.57,
          latitude: 50.03,
          baroAltitude: 10000,
          velocity: 230,
          trueTrack: 180,
        );

        final results = await service.search(
          'DLH123',
          liveAircraft: {'3c664e': aircraft},
        );

        expect(results.first.type, SearchResultType.liveAircraft);
        expect(results.first.title, 'LH123');
        expect(results.first.aircraft?.callsign, 'DLH123');
      },
    );

    test(
      'matches Tunisair IATA flight query against ICAO callsign and displays IATA',
      () async {
        final service = SearchService();
        final aircraft = AircraftState(
          icao24: '02a1b2',
          callsign: 'TAR744',
          originCountry: 'Tunisia',
          longitude: 10.23,
          latitude: 36.85,
          baroAltitude: 9500,
          velocity: 210,
          trueTrack: 45,
        );

        final results = await service.search(
          'TU744',
          liveAircraft: {'02a1b2': aircraft},
        );

        expect(results.first.type, SearchResultType.liveAircraft);
        expect(results.first.title, 'TU744');
        expect(results.first.aircraft?.callsign, 'TAR744');
      },
    );

    test('resolves selected aircraft from IATA-formatted flight result', () {
      final service = SearchService();
      final aircraft = AircraftState(
        icao24: '02a1b2',
        callsign: 'TAR744',
        originCountry: 'Tunisia',
        longitude: 10.23,
        latitude: 36.85,
        baroAltitude: 9500,
        velocity: 210,
        trueTrack: 45,
      );

      final selected = service.resolveSelectedAircraft(
        const SearchResultItem(
          type: SearchResultType.apiResult,
          title: 'TU744',
          flightIata: 'TU744',
          flightIcao: 'TAR744',
        ),
        liveAircraft: {'02a1b2': aircraft},
      );

      expect(selected?.callsign, 'TAR744');
    });

    test('prioritizes exact airline code matches', () async {
      final service = SearchService();

      final results = await service.search('DLH', liveAircraft: const {});

      expect(results.first.type, SearchResultType.airline);
      expect(results.first.airlineIcao, 'DLH');
    });

    test('finds airlines by name prefix', () async {
      final service = SearchService();

      final results = await service.search('LUFT', liveAircraft: const {});

      expect(
        results.any(
          (item) =>
              item.type == SearchResultType.airline &&
              item.title.toUpperCase().contains('LUFTHANSA'),
        ),
        isTrue,
      );
    });
  });
}
