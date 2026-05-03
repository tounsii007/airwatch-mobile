import 'package:airwatch_mobile/core/constants/country_database.dart';
import 'package:airwatch_mobile/core/utils/flight_code_formatter.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/search/data/models/search_models.dart';

// ═══════════════════ RANKING & DEDUPLICATION ═══════════════════

List<SearchResultItem> rankAndDeduplicate(
  List<SearchResultItem> results,
  String query,
) {
  final deduped = <String, SearchResultItem>{};

  for (final result in results) {
    final key = dedupeKey(result);
    final existing = deduped[key];
    if (existing == null || compareResults(result, existing, query) < 0) {
      deduped[key] = result;
    }
  }

  final ranked = deduped.values.toList(growable: false)
    ..sort((a, b) => compareResults(a, b, query));
  return ranked;
}

String dedupeKey(SearchResultItem result) {
  return switch (result.type) {
    SearchResultType.liveAircraft =>
      'live:${result.aircraft?.icao24 ?? result.title}',
    SearchResultType.airline => 'airline:${result.airlineIcao ?? result.title}',
    SearchResultType.country => 'country:${result.countryCode ?? result.title}',
    SearchResultType.apiResult || SearchResultType.airlineFlight =>
      'flight:${result.flightIata ?? result.flightIcao ?? result.title}',
  };
}

int compareResults(SearchResultItem a, SearchResultItem b, String query) {
  final rankA = globalRank(a, query);
  final rankB = globalRank(b, query);
  final byRank = rankA.compareTo(rankB);
  if (byRank != 0) return byRank;

  final typeA = typePriority(a.type);
  final typeB = typePriority(b.type);
  final byType = typeA.compareTo(typeB);
  if (byType != 0) return byType;

  return a.title.compareTo(b.title);
}

int globalRank(SearchResultItem result, String query) {
  final title = result.title.toUpperCase();
  final subtitle = result.subtitle.toUpperCase();

  if (title == query) return 0;
  if (result.type == SearchResultType.airline &&
      result.airlineIcao?.toUpperCase() == query) {
    return 0;
  }
  if (result.type == SearchResultType.airline &&
      result.airlineIata?.toUpperCase() == query) {
    return 1;
  }
  if (result.type == SearchResultType.country &&
      result.countryCode?.toUpperCase() == query) {
    return 1;
  }
  if (title.startsWith(query)) return 2;
  if (subtitle.startsWith(query)) return 3;
  if (title.contains(query)) return 4;
  if (subtitle.contains(query)) return 5;
  return 6 + typePriority(result.type);
}

int typePriority(SearchResultType type) {
  return switch (type) {
    SearchResultType.liveAircraft => 0,
    SearchResultType.airline => 1,
    SearchResultType.apiResult => 2,
    SearchResultType.airlineFlight => 3,
    SearchResultType.country => 4,
  };
}

String preferredFlightTitle({
  String? flightIata,
  String? flightIcao,
  required String fallback,
}) {
  return FlightCodeFormatter.displayFlightCode(
    flightIata: flightIata,
    flightIcao: flightIcao,
    fallback: fallback,
  );
}

// ═══════════════════ HELPER CLASSES ═══════════════════

class FlightLookupRequest {
  final String? flightIcao;
  final String? flightIata;

  const FlightLookupRequest.byIcao(String value)
    : flightIcao = value,
      flightIata = null;

  const FlightLookupRequest.byIata(String value)
    : flightIcao = null,
      flightIata = value;
}

class LiveAircraftSearchEntry {
  final AircraftState aircraft;
  final String callsign;
  final String icao24;
  final String originCountry;
  final String? countryCode;
  final String iataDisplay;
  final Set<String> prefixes;

  LiveAircraftSearchEntry(this.aircraft)
    : callsign = aircraft.callsign?.trim().toUpperCase() ?? '',
      icao24 = aircraft.icao24.toUpperCase(),
      originCountry = (aircraft.originCountry ?? '').toUpperCase(),
      countryCode = CountryDatabase.codeOf(aircraft.originCountry),
      iataDisplay = FlightCodeFormatter.displayFlightCode(
        callsign: aircraft.callsign,
      ),
      prefixes = _prefixesFor(aircraft);

  String get displayTitle {
    if (iataDisplay.isNotEmpty) return iataDisplay;
    if (callsign.isNotEmpty) return callsign;
    return icao24;
  }

  int? score(String query) {
    return switch (true) {
      _ when iataDisplay.isNotEmpty && iataDisplay == query => 0,
      _ when iataDisplay.isNotEmpty && iataDisplay.startsWith(query) => 1,
      _ when callsign.isNotEmpty && callsign == query => 0,
      _ when icao24 == query => 2,
      _ when countryCode == query => 3,
      _ when originCountry == query => 4,
      _ when callsign.startsWith(query) => 5,
      _ when icao24.startsWith(query) => 6,
      _ when _startsWithWord(originCountry, query) => 7,
      _ when iataDisplay.isNotEmpty && iataDisplay.contains(query) => 8,
      _ when callsign.contains(query) => 9,
      _ when icao24.contains(query) => 10,
      _ when originCountry.contains(query) => 11,
      _ when countryCode?.contains(query) ?? false => 12,
      _ => null,
    };
  }

  bool _startsWithWord(String value, String query) {
    return value.startsWith(query) || value.contains(' $query');
  }

  static Set<String> _prefixesFor(AircraftState aircraft) {
    final prefixes = <String>{};

    void addPrefix(String value) {
      final normalized = value.toUpperCase().trim();
      if (normalized.isEmpty) return;
      final prefix = normalized.length >= 2
          ? normalized.substring(0, 2)
          : normalized;
      prefixes.add(prefix);
    }

    addPrefix(aircraft.callsign ?? '');
    addPrefix(aircraft.icao24);
    addPrefix(aircraft.originCountry ?? '');
    addPrefix(CountryDatabase.codeOf(aircraft.originCountry) ?? '');
    addPrefix(
      FlightCodeFormatter.displayFlightCode(callsign: aircraft.callsign),
    );

    for (final token in (aircraft.originCountry ?? '').split(
      RegExp(r'[^A-Za-z0-9]+'),
    )) {
      addPrefix(token);
    }

    return prefixes;
  }
}

class AirlineSearchEntry {
  final AirlineInfo airline;
  final String icao;
  final String iata;
  final String name;
  final String country;
  final Set<String> prefixes;

  AirlineSearchEntry(this.airline)
    : icao = airline.icao.toUpperCase(),
      iata = airline.iata.toUpperCase(),
      name = airline.name.toUpperCase(),
      country = airline.country.toUpperCase(),
      prefixes = _prefixesFor(airline);

  int? score(String query) {
    return switch (true) {
      _ when icao == query => 0,
      _ when iata.isNotEmpty && iata == query => 1,
      _ when name == query => 2,
      _ when country.isNotEmpty && country == query => 3,
      _ when icao.startsWith(query) => 4,
      _ when iata.isNotEmpty && iata.startsWith(query) => 5,
      _ when _startsWithWord(name, query) => 6,
      _ when _startsWithWord(country, query) => 7,
      _ when name.contains(query) => 8,
      _ when country.isNotEmpty && country.contains(query) => 9,
      _ => null,
    };
  }

  bool _startsWithWord(String value, String query) {
    return value.startsWith(query) || value.contains(' $query');
  }

  static Set<String> _prefixesFor(AirlineInfo airline) {
    final prefixes = <String>{};

    void addPrefix(String value) {
      final normalized = value.toUpperCase().trim();
      if (normalized.isEmpty) return;
      final prefix = normalized.length >= 2
          ? normalized.substring(0, 2)
          : normalized;
      prefixes.add(prefix);
    }

    addPrefix(airline.icao);
    addPrefix(airline.iata);

    for (final token in airline.name.split(RegExp(r'[^A-Za-z0-9]+'))) {
      addPrefix(token);
    }
    for (final token in airline.country.split(RegExp(r'[^A-Za-z0-9]+'))) {
      addPrefix(token);
    }

    return prefixes;
  }
}
