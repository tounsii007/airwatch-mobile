import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:airwatch_mobile/core/constants/api_json_keys.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/constants/country_database.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';
import 'package:airwatch_mobile/core/utils/flight_code_formatter.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/search/data/models/search_models.dart';
import 'package:airwatch_mobile/features/search/data/services/search_ranking.dart';

class SearchService {
  final Dio _dio;

  SearchService({Dio? dio})
      : _dio = dio ??
            AppHttpClient.create(
              connectTimeout: AppConfig.apiTimeout,
              receiveTimeout: AppConfig.apiTimeout,
            );

  /// Session cache of all aircraft ever seen during this app session.
  /// Allows searching for flights that have landed since the app started.
  static final Map<String, AircraftState> _seenAircraft = {};

  /// Call this periodically to capture live aircraft into session cache.
  static void updateSeenAircraft(Map<String, AircraftState> liveAircraft) {
    _seenAircraft.addAll(liveAircraft);
  }

  static final List<AirlineInfo> _airlines = FlightInfoDatasource.staticAirlineList;
  static final List<AirlineSearchEntry> _airlineEntries = _airlines
      .map(AirlineSearchEntry.new)
      .toList(growable: false);
  static final Map<String, List<AirlineSearchEntry>> _airlineBuckets =
      _buildAirlineBuckets();

  /// Main search method — searches across multiple data sources:
  ///
  /// 1. Session cache (free, instant) — aircraft seen during this app session
  /// 2. Live aircraft stream (free, instant) — currently tracked aircraft
  /// 3. Airline database (free, instant) — offline airline lookup
  /// 4. /flight API (1 call) — single flight lookup (live + recently landed)
  /// 5. /routes API (1 call) — static route data (always available)
  /// 6. /schedules API (1 call) — today's schedule including landed flights
  ///
  /// API Usage per search: Up to 3 calls worst case.
  /// Free Plan budget: ~333 searches/month (1,000 calls / 3).
  /// TODO: With Starter Plan (9.90 USD, 10,000 calls) → ~3,333 searches/month.
  Future<List<SearchResultItem>> search(
    String query, {
    required Map<String, AircraftState> liveAircraft,
  }) async {
    final q = query.trim().toUpperCase();
    if (q.isEmpty) return const [];

    // Update session cache with current live aircraft
    updateSeenAircraft(liveAircraft);

    final results = <SearchResultItem>[
      ..._searchLiveAircraft(q, liveAircraft),
      ..._searchSeenAircraft(q, liveAircraft),
    ];

    results.addAll(_searchAirlines(q));

    if (q.length >= 3 && !_isOnlyLetters(q)) {
      // 1. Try live /flight endpoint — finds active + recently landed flights
      //    NOTE: Free Plan (1,000 calls/month). Returns closest match (live/scheduled/landed).
      final flightResult = await _searchFlight(q, results);
      if (flightResult != null) {
        results.add(flightResult);
      }

      // 2. Try /routes endpoint — static schedule data, always works regardless of flight status
      //    NOTE: Free Plan included. No rate limit concern since it's cached by Airlabs.
      final hasFlightMatch = results.any((r) =>
          r.type == SearchResultType.apiResult ||
          r.type == SearchResultType.airlineFlight);
      if (!hasFlightMatch) {
        final routeResult = await _searchRoute(q);
        if (routeResult != null) {
          results.add(routeResult);
        }
      }

      // 3. Try /schedules endpoint — finds today's flights including landed ones
      //    NOTE: Free Plan limited to 50 results per call, counts against 1,000 calls/month.
      //    This is the most reliable way to find landed flights from today.
      //    TODO: Upgrade to Starter Plan (9.90 USD/month, 10,000 calls) for production use.
      if (!hasFlightMatch && results.every((r) => r.type != SearchResultType.apiResult)) {
        final scheduleResult = await _searchSchedule(q);
        if (scheduleResult != null) {
          results.add(scheduleResult);
        }
      }
    }

    if (q.length >= 2 && q.length <= 3 && _isOnlyLetters(q)) {
      final airlineFlights = await _searchAirlineFlights(q, results);
      results.addAll(airlineFlights);
    }

    // Country search — `Frankreich`, `France`, `FR`, `FRA` all match.
    // Wired in here so the SearchResultType.country branch in
    // resolveSelectedAircraft / filterResults isn't dead code.
    if (q.length >= 2) {
      results.addAll(_searchCountries(q, current: results));
    }

    return rankAndDeduplicate(results, q);
  }

  List<SearchResultItem> filterResults(
    List<SearchResultItem> results,
    SearchFilter filter,
  ) {
    if (filter == SearchFilter.all) return results;
    return results.where((result) {
      return switch (filter) {
        SearchFilter.all => true,
        SearchFilter.live => result.type == SearchResultType.liveAircraft,
        SearchFilter.airlines => result.type == SearchResultType.airline,
        SearchFilter.flights =>
          result.type == SearchResultType.apiResult ||
              result.type == SearchResultType.airlineFlight,
        SearchFilter.countries => result.type == SearchResultType.country,
      };
    }).toList();
  }

  AircraftState? resolveSelectedAircraft(
    SearchResultItem result, {
    required Map<String, AircraftState> liveAircraft,
  }) {
    final resultIds = FlightCodeFormatter.identifiers(
      flightIata: result.flightIata,
      flightIcao: result.flightIcao,
      fallback: result.title,
    );

    return switch (result.type) {
      SearchResultType.liveAircraft => result.aircraft,
      SearchResultType.airline => null,
      SearchResultType.country => null,
      SearchResultType.apiResult || SearchResultType.airlineFlight => liveAircraft
          .values
          .where(
            (item) => FlightCodeFormatter.identifiers(
              callsign: item.callsign,
              fallback: item.icao24,
            ).intersection(resultIds).isNotEmpty,
          )
          .firstOrNull,
    };
  }

  List<SearchResultItem> _searchCountries(
    String query, {
    required List<SearchResultItem> current,
  }) {
    final alreadyAdded = current
        .map((item) => item.countryCode)
        .whereType<String>()
        .toSet();

    return CountryDatabase.search(query, limit: 8)
        .where((country) => !alreadyAdded.contains(country.code))
        .map(
          (country) => SearchResultItem(
            type: SearchResultType.country,
            title: country.name,
            subtitle: country.code,
            countryCode: country.code,
          ),
        )
        .toList(growable: false);
  }

  /// Search via /flight endpoint — returns the closest matching flight (live, scheduled, or landed).
  ///
  /// API: GET /api/v9/flight?flight_iata=TU744
  /// Returns: Single flight with full details (aircraft, route, times, position).
  /// Free Plan: Counts as 1 of 1,000 monthly calls.
  /// Starter Plan (9.90 USD): 1 of 10,000 calls.
  Future<SearchResultItem?> _searchFlight(
    String query,
    List<SearchResultItem> current,
  ) async {
    try {
      for (final request in _flightRequestsForQuery(query)) {
        final response = await _dio.get(
          AppConfig.flightUrl(
            flightIcao: request.flightIcao,
            flightIata: request.flightIata,
          ),
        );
        if (response.statusCode == 200 && response.data is Map) {
          final data = response.data as Map;
          final flight = data[ApiJsonKeys.response] as Map?;
          if (flight != null && flight.isNotEmpty) {
            final flightIcao = flight['flight_icao']?.toString();
            final flightIata = flight['flight_iata']?.toString();
            final alreadyLive = current.any(
              (r) =>
                  r.type == SearchResultType.liveAircraft &&
                  (r.title == query ||
                      r.title == flightIcao ||
                      r.title == flightIata),
            );
            if (!alreadyLive) {
              return SearchResultItem(
                type: SearchResultType.apiResult,
                title: preferredFlightTitle(
                  flightIata: flightIata,
                  flightIcao: flightIcao,
                  fallback: query,
                ),
                flightIcao: flightIcao,
                flightIata: flightIata,
                subtitle:
                    '${flight['dep_iata'] ?? "?"} -> ${flight['arr_iata'] ?? "?"}',
                status: flight[ApiJsonKeys.status]?.toString(),
                depIata: flight['dep_iata']?.toString(),
                arrIata: flight['arr_iata']?.toString(),
              );
            }
          }
        }
      }
    } catch (e) {
      // Log API errors for debugging — don't silently swallow
      assert(() { debugPrint('[Search] Flight lookup failed: $e'); return true; }());
    }
    return null;
  }

  /// Search via /routes endpoint — static route database.
  /// Always returns data regardless of whether the flight is active or landed.
  ///
  /// API: GET /api/v9/routes?flight_iata=TU744
  /// Returns: Static route info (DEP → ARR), no real-time status.
  /// Free Plan: Counts as 1 of 1,000 monthly calls.
  Future<SearchResultItem?> _searchRoute(String query) async {
    try {
      for (final request in _flightRequestsForQuery(query)) {
        final response = await _dio.get(
          AppConfig.routesUrl(
            flightIcao: request.flightIcao,
            flightIata: request.flightIata,
          ),
        );
        if (response.statusCode == 200 && response.data is Map) {
          final routes = (response.data as Map)[ApiJsonKeys.response] as List?;
          if (routes != null && routes.isNotEmpty) {
            final route = routes.first as Map;
            return SearchResultItem(
              type: SearchResultType.apiResult,
              title: preferredFlightTitle(
                flightIata: route['flight_iata']?.toString(),
                flightIcao: route['flight_icao']?.toString(),
                fallback: query,
              ),
              flightIcao: route['flight_icao']?.toString(),
              flightIata: route['flight_iata']?.toString(),
              subtitle:
                  '${route['dep_iata'] ?? "?"} -> ${route['arr_iata'] ?? "?"}'
                  '${route['dep_time'] != null ? " - ${route['dep_time']}" : ""}',
              status: 'scheduled',
              depIata: route['dep_iata']?.toString(),
              arrIata: route['arr_iata']?.toString(),
            );
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Search via /schedules endpoint — finds today's flights including landed ones.
  /// This endpoint returns the full daily schedule for a flight number.
  ///
  /// API: GET /api/v9/schedules?flight_iata=TU744
  /// Free Plan: 50 results max, counts against 1,000 monthly calls.
  /// Starter Plan (9.90 USD/month): 200 results, 10,000 calls.
  /// Developer Plan (49 USD/month): 200 results, 25,000 calls.
  Future<SearchResultItem?> _searchSchedule(String query) async {
    try {
      for (final request in _flightRequestsForQuery(query)) {
        final response = await _dio.get(
          AppConfig.scheduleByFlightUrl(
            flightIcao: request.flightIcao,
            flightIata: request.flightIata,
          ),
        );
        if (response.statusCode == 200 && response.data is Map) {
          final schedules = (response.data as Map)[ApiJsonKeys.response] as List?;
          if (schedules != null && schedules.isNotEmpty) {
            final s = schedules.first as Map;
            final flightIcao = s[ApiJsonKeys.flightIcao]?.toString();
            final flightIata = s[ApiJsonKeys.flightIata]?.toString();
            final status = s[ApiJsonKeys.status]?.toString();
            final depIata = s[ApiJsonKeys.depIata]?.toString();
            final arrIata = s[ApiJsonKeys.arrIata]?.toString();

            return SearchResultItem(
              type: SearchResultType.apiResult,
              title: preferredFlightTitle(
                flightIata: flightIata,
                flightIcao: flightIcao,
                fallback: query,
              ),
              flightIcao: flightIcao,
              flightIata: flightIata,
              subtitle: '${depIata ?? "?"} → ${arrIata ?? "?"}',
              status: status,
              depIata: depIata,
              arrIata: arrIata,
            );
          }
        }
      }
    } catch (e) {
      // NOTE: /schedules may fail on Free Plan if monthly limit (1,000) is reached.
      // Upgrade to Starter Plan (9.90 USD/month) for 10,000 calls.
      assert(() { debugPrint('[Search] Schedule lookup failed: $e'); return true; }());
    }
    return null;
  }

  Future<List<SearchResultItem>> _searchAirlineFlights(
    String query,
    List<SearchResultItem> current,
  ) async {
    try {
      final response = await _dio.get(
        AppConfig.flightsUrl(
          'airline_icao=$query&_fields=flight_icao,flight_iata,dep_iata,arr_iata,status',
        ),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final flights = (response.data as Map)[ApiJsonKeys.response] as List?;
        if (flights == null) return const [];

        final items = <SearchResultItem>[];
        for (final raw in flights.take(30)) {
          if (raw is! Map) continue;
          final flightIcao = raw['flight_icao']?.toString() ?? '';
          if (current.any((r) => r.title == flightIcao) ||
              items.any((r) => r.title == flightIcao)) {
            continue;
          }
          items.add(
            SearchResultItem(
              type: SearchResultType.airlineFlight,
              title: preferredFlightTitle(
                flightIata: raw['flight_iata']?.toString(),
                flightIcao: flightIcao,
                fallback: flightIcao,
              ),
              flightIcao: flightIcao,
              flightIata: raw['flight_iata']?.toString(),
              subtitle:
                  '${raw['dep_iata'] ?? "?"} -> ${raw['arr_iata'] ?? "?"}',
              status: raw[ApiJsonKeys.status]?.toString(),
              depIata: raw['dep_iata']?.toString(),
              arrIata: raw['arr_iata']?.toString(),
            ),
          );
        }
        return items;
      }
    } catch (_) {}
    return const [];
  }

  bool _isOnlyLetters(String value) => RegExp(r'^[A-Z]+$').hasMatch(value);

  List<SearchResultItem> _searchLiveAircraft(
    String query,
    Map<String, AircraftState> liveAircraft,
  ) {
    final entries = liveAircraft.values
        .map(LiveAircraftSearchEntry.new)
        .toList(growable: false);
    final buckets = <String, List<LiveAircraftSearchEntry>>{};

    for (final entry in entries) {
      for (final prefix in entry.prefixes) {
        buckets.putIfAbsent(prefix, () => <LiveAircraftSearchEntry>[]).add(entry);
      }
    }

    // Locale-aware country fallback: if the raw query resolves to a known
    // country (e.g. user typed "Tunesien" / "Tunisie"), also score every
    // entry against the canonical English country name + ISO code so we
    // don't miss aircraft just because the API returns names in English.
    final localeMatch = CountryDatabase.find(query);
    final localeCountryCode = localeMatch?.code.toUpperCase();
    final localeCountryName = localeMatch?.name.toUpperCase();

    // Build the candidate set: bucket-by-prefix is a fast path for
    // callsign / ICAO / IATA queries. When the locale-country fallback
    // is active we have to consider every aircraft, since the user query
    // ("Tunesien") doesn't share a 2-char prefix with the indexed
    // country code ("TN"). Falling back to the full list in that case
    // is cheap — even 8000 entries fit through the score() loop in <2 ms.
    final prefix = query.length >= 2 ? query.substring(0, 2) : query;
    final candidates =
        localeCountryCode != null ? entries : (buckets[prefix] ?? entries);

    int? scoreOf(LiveAircraftSearchEntry e) {
      final byQuery = e.score(query);
      if (byQuery != null) return byQuery;
      if (localeCountryCode != null && e.countryCode == localeCountryCode) {
        // Same priority as the existing `countryCode == query` branch in
        // LiveAircraftSearchEntry.score (= 3), so localised matches rank
        // alongside an exact ISO-code typed query.
        return 3;
      }
      if (localeCountryName != null && e.originCountry == localeCountryName) {
        return 4;
      }
      return null;
    }

    final scored = candidates
        .map((entry) => (entry: entry, score: scoreOf(entry)))
        .where((result) => result.score != null)
        .map((result) => (entry: result.entry, score: result.score!))
        .toList(growable: false)
      ..sort((a, b) {
        final byScore = a.score.compareTo(b.score);
        if (byScore != 0) return byScore;
        return a.entry.displayTitle.compareTo(b.entry.displayTitle);
      });

    return scored
        .take(20)
        .map(
          (result) => SearchResultItem(
            type: SearchResultType.liveAircraft,
            title: result.entry.displayTitle,
            subtitle: result.entry.originCountry,
            status: result.entry.aircraft.onGround ? 'on ground' : 'en-route',
            altitude: result.entry.aircraft.altitude,
            aircraft: result.entry.aircraft,
          ),
        )
        .toList(growable: false);
  }

  /// Search aircraft seen earlier in this session but no longer live.
  List<SearchResultItem> _searchSeenAircraft(
    String query,
    Map<String, AircraftState> liveAircraft,
  ) {
    // Only search aircraft NOT in the current live set
    final offlineAircraft = _seenAircraft.entries
        .where((e) => !liveAircraft.containsKey(e.key))
        .map((e) => e.value);

    return offlineAircraft
        .where((a) {
          final cs = a.callsign?.toUpperCase() ?? '';
          final icao = a.icao24.toUpperCase();
          return cs.contains(query) || icao.contains(query);
        })
        .take(10)
        .map((a) {
          final cs = FlightCodeFormatter.displayFlightCode(
            callsign: a.callsign,
            fallback: a.icao24,
          );
          return SearchResultItem(
            type: SearchResultType.liveAircraft,
            title: cs,
            // originCountry is nullable on AircraftState — fall back to
            // the empty string so the constructor's non-null `subtitle`
            // contract holds.
            subtitle: a.originCountry ?? '',
            status: 'landed',
            altitude: a.altitude,
            aircraft: a,
          );
        })
        .toList();
  }

  List<SearchResultItem> _searchAirlines(String query) {
    final candidates = _airlineCandidates(query);
    final scored = candidates
        .map((entry) => (entry: entry, score: entry.score(query)))
        .where((result) => result.score != null)
        .map((result) => (entry: result.entry, score: result.score!))
        .toList(growable: false)
      ..sort((a, b) {
        final byScore = a.score.compareTo(b.score);
        if (byScore != 0) return byScore;
        return a.entry.airline.name.compareTo(b.entry.airline.name);
      });

    return scored
        .take(20)
        .map((result) => _airlineItem(result.entry.airline))
        .toList(growable: false);
  }

  List<AirlineSearchEntry> _airlineCandidates(String query) {
    final prefix = query.length >= 2 ? query.substring(0, 2) : query;
    final candidates = _airlineBuckets[prefix];
    if (candidates != null && candidates.isNotEmpty) {
      return candidates;
    }
    return _airlineEntries;
  }

  SearchResultItem _airlineItem(AirlineInfo airline) {
    return SearchResultItem(
      type: SearchResultType.airline,
      title: airline.name,
      subtitle: '${airline.iata} / ${airline.icao} - ${airline.country}',
      airlineIcao: airline.icao,
      airlineIata: airline.iata,
    );
  }

  static Map<String, List<AirlineSearchEntry>> _buildAirlineBuckets() {
    final buckets = <String, List<AirlineSearchEntry>>{};
    for (final entry in _airlineEntries) {
      for (final prefix in entry.prefixes) {
        buckets.putIfAbsent(prefix, () => <AirlineSearchEntry>[]).add(entry);
      }
    }
    return buckets;
  }

  List<FlightLookupRequest> _flightRequestsForQuery(String query) {
    final parsed = FlightCodeFormatter.parseFlightCode(query);
    if (parsed == null) {
      return [FlightLookupRequest.byIcao(query)];
    }

    final iataMatches = FlightCodeFormatter.resolveByIata(parsed.prefix);
    if (parsed.prefix.length <= 2 && iataMatches.isNotEmpty) {
      return [
        FlightLookupRequest.byIata(query),
        for (final airline in iataMatches)
          FlightLookupRequest.byIcao('${airline.icao}${parsed.suffix}'),
      ];
    }

    return [
      FlightLookupRequest.byIcao(query),
      if (parsed.prefix.length <= 2) FlightLookupRequest.byIata(query),
    ];
  }

}
