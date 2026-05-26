import 'package:airwatch_mobile/core/constants/airline_database.dart';

class ParsedFlightCode {
  final String prefix;
  final String suffix;

  const ParsedFlightCode({required this.prefix, required this.suffix});
}

class FlightCodeFormatter {
  static final List<AirlineInfo> _airlines = airlineList;
  static final Map<String, AirlineInfo> _airlinesByIcao = {
    for (final airline in _airlines) airline.icao.toUpperCase(): airline,
  };
  static final Map<String, List<AirlineInfo>> _airlinesByIata = _buildByIata();

  static AirlineInfo? resolveAirline(String? callsign) {
    if (callsign == null || callsign.trim().length < 3) {
      return null;
    }
    final icao = callsign.trim().substring(0, 3).toUpperCase();
    return _airlinesByIcao[icao];
  }

  static List<AirlineInfo> resolveByIata(String? iata) {
    final normalized = _normalize(iata);
    if (normalized.length < 2 || normalized.length > 3) {
      return const <AirlineInfo>[];
    }
    return _airlinesByIata[normalized] ?? const <AirlineInfo>[];
  }

  /// Pre-compiled flight-code RegExp. The previous in-method literal
  /// caused Dart to construct a fresh RegExp object (with its own
  /// compiled state machine) on every call. parseFlightCode is invoked
  /// in tile builders across cargo, search, history, etc.
  static final RegExp _flightCodeRe = RegExp(
    r'^([A-Z0-9]{2,3})([0-9]{1,4}[A-Z]?)$',
  );

  static ParsedFlightCode? parseFlightCode(String? value) {
    final normalized = _normalize(value);
    final match = _flightCodeRe.firstMatch(normalized);
    if (match == null) {
      return null;
    }
    return ParsedFlightCode(prefix: match.group(1)!, suffix: match.group(2)!);
  }

  static String displayFlightCode({
    String? flightIata,
    String? flightIcao,
    String? callsign,
    String? fallback,
    bool spaced = false,
  }) {
    final normalizedIata = _normalize(flightIata);
    if (normalizedIata.isNotEmpty) {
      return spaced && normalizedIata.length > 2
          ? '${normalizedIata.substring(0, 2)} ${normalizedIata.substring(2)}'
          : normalizedIata;
    }

    final fromCallsign = _iataDisplayFromCallsign(callsign ?? flightIcao);
    if (fromCallsign.isNotEmpty) {
      return spaced && fromCallsign.length > 2
          ? '${fromCallsign.substring(0, 2)} ${fromCallsign.substring(2)}'
          : fromCallsign;
    }

    final normalizedIcao = _normalize(flightIcao ?? callsign);
    if (normalizedIcao.isNotEmpty) {
      return normalizedIcao;
    }

    return _normalize(fallback);
  }

  static Set<String> identifiers({
    String? flightIata,
    String? flightIcao,
    String? callsign,
    String? fallback,
  }) {
    final values = <String>{};

    void add(String? value) {
      final normalized = _normalize(value);
      if (normalized.isNotEmpty) {
        values.add(normalized);
      }
    }

    add(flightIata);
    add(flightIcao);
    add(callsign);
    add(fallback);
    add(_iataDisplayFromCallsign(callsign ?? flightIcao));

    return values;
  }

  static String _iataDisplayFromCallsign(String? callsign) {
    final normalized = _normalize(callsign);
    if (normalized.length < 4) {
      return '';
    }
    final airline = resolveAirline(normalized);
    final iata = _normalize(airline?.iata);
    if (iata.isEmpty) {
      return '';
    }
    final suffix = normalized.substring(3);
    if (suffix.isEmpty) {
      return '';
    }
    return '$iata$suffix';
  }

  static String _normalize(String? value) => value?.trim().toUpperCase() ?? '';

  static Map<String, List<AirlineInfo>> _buildByIata() {
    final map = <String, List<AirlineInfo>>{};
    for (final airline in _airlines) {
      final iata = _normalize(airline.iata);
      if (iata.isEmpty) {
        continue;
      }
      map.putIfAbsent(iata, () => <AirlineInfo>[]).add(airline);
    }
    return map;
  }
}
