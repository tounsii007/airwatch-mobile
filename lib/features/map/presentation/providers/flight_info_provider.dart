import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airwatch_mobile/core/utils/flight_code_formatter.dart';
import '../../data/datasources/flight_info_datasource.dart';
import '../../data/models/aircraft_state.dart';

final flightInfoDatasourceProvider = Provider<FlightInfoDatasource>((ref) {
  return FlightInfoDatasource();
});

/// Combined flight details for the selected aircraft
class FlightDetails {
  final AircraftState aircraft;
  final AirlineInfo? airline;
  final FlightRouteInfo? route;
  final AircraftMetadata? metadata;
  final String? airlineLogoUrl;
  final bool isLoading;

  FlightDetails({
    required this.aircraft,
    this.airline,
    this.route,
    this.metadata,
    this.airlineLogoUrl,
    this.isLoading = false,
  });

  String get displayName {
    if (airline != null) return airline!.name;
    if (metadata?.operatorName != null) return metadata!.operatorName!;
    return aircraft.originCountry ?? 'Unknown';
  }

  String get displayFlightNumber {
    return FlightCodeFormatter.displayFlightCode(
      callsign: aircraft.callsign,
      fallback: aircraft.icao24,
      spaced: true,
    );
  }

  String get displayAircraftType {
    if (metadata != null) return metadata!.displayType;
    return _guessTypeFromCategory(aircraft.category);
  }

  String get displayRegistration {
    return metadata?.registration ?? aircraft.icao24.toUpperCase();
  }

  String get departureCode => route?.departureAirport ?? '???';
  String get arrivalCode => route?.arrivalAirport ?? '???';

  static String _guessTypeFromCategory(int category) {
    switch (category) {
      case 1:
        return 'Light Aircraft';
      case 2:
        return 'Small Aircraft';
      case 3:
        return 'Large Aircraft';
      case 4:
        return 'High Vortex Large';
      case 5:
        return 'Heavy Aircraft';
      case 6:
        return 'High Performance';
      case 7:
        return 'Rotorcraft';
      default:
        return 'Unknown Type';
    }
  }
}

/// Provider that fetches full details when an aircraft is selected
final flightDetailsProvider = FutureProvider.autoDispose<FlightDetails?>((
  ref,
) async {
  final aircraft = ref.watch(selectedAircraftNotifierProvider);
  if (aircraft == null) return null;

  final datasource = ref.read(flightInfoDatasourceProvider);

  // Resolve airline from callsign (instant, offline)
  final airline = datasource.resolveAirline(aircraft.callsign);
  final logoUrl = airline != null
      ? FlightInfoDatasource.getAirlineLogoUrl(airline.iata)
      : null;

  // Start async fetches in parallel
  final routeFuture = datasource.getRouteByCallsign(
    aircraft.callsign?.trim() ?? '',
  );
  final metadataFuture = datasource.getAircraftByIcao24(aircraft.icao24);

  // Return immediately with what we have, then update
  final results = await Future.wait([routeFuture, metadataFuture]);

  final route = results[0] as FlightRouteInfo?;
  final metadata = results[1] as AircraftMetadata?;

  // If we got operator from metadata but not from callsign, try to find logo
  String? finalLogoUrl = logoUrl;
  if (finalLogoUrl == null && metadata?.operatorIcao != null) {
    final metaAirline = _airlineLookupByIcao[metadata!.operatorIcao];
    if (metaAirline != null) {
      finalLogoUrl = FlightInfoDatasource.getAirlineLogoUrl(metaAirline);
    }
  }

  return FlightDetails(
    aircraft: aircraft,
    airline: airline,
    route: route,
    metadata: metadata,
    airlineLogoUrl: finalLogoUrl,
  );
});

// Quick lookup for the selectedAircraft from main providers
final selectedAircraftNotifierProvider = Provider<AircraftState?>((ref) {
  // Import from main providers
  return ref.watch(_selectedAircraftProviderProxy);
});

// This will be wired in the actual import
final _selectedAircraftProviderProxy = Provider<AircraftState?>((ref) {
  // Re-export from the main flight_providers
  return null;
});

const Map<String, String> _airlineLookupByIcao = {
  'AAL': 'AA',
  'AFR': 'AF',
  'BAW': 'BA',
  'DAL': 'DL',
  'DLH': 'LH',
  'EIN': 'EI',
  'ETD': 'EY',
  'EZY': 'U2',
  'IBE': 'IB',
  'KLM': 'KL',
  'QFA': 'QF',
  'QTR': 'QR',
  'RYR': 'FR',
  'SAS': 'SK',
  'SIA': 'SQ',
  'SWR': 'LX',
  'THY': 'TK',
  'UAE': 'EK',
  'UAL': 'UA',
  'WZZ': 'W6',
};
