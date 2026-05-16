import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:airwatch_mobile/core/constants/airline_database.dart'
    as airline_db;
import 'package:airwatch_mobile/core/constants/api_json_keys.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/models/airline_info.dart';
export 'package:airwatch_mobile/core/models/airline_info.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';
import 'airlabs_datasource.dart';

/// Resolves additional flight information from callsign/ICAO24.
/// Uses multiple data sources (aggregated):
/// 1. Built-in ICAO airline database (offline, fast)
/// 2. OpenSky route API (free, no key)
/// 3. Hexdb.io for aircraft metadata (free, no key)
class FlightInfoDatasource {
  final Dio _dio;

  final AirlabsDatasource _airlabs = AirlabsDatasource();

  FlightInfoDatasource({Dio? dio})
    : _dio = dio ?? AppHttpClient.create(receiveTimeout: AppConfig.apiTimeout);

  // Session cache for routes — avoids repeated API calls for the same aircraft
  static final Map<String, FlightRouteInfo?> _routeCache = {};

  /// Get route info — tries multiple sources with caching:
  /// 1. Session cache
  /// 2. OpenSky /api/routes (fast but often 404)
  /// 3. OpenSky /api/tracks (live track, infers departure)
  /// 4. OpenSky /api/flights/aircraft (historical fallback)
  Future<FlightRouteInfo?> getRouteByCallsign(
    String callsign, {
    String? icao24,
  }) async {
    final cacheKey = '${callsign.trim()}_${icao24 ?? ""}';

    // Check cache first
    if (_routeCache.containsKey(cacheKey)) {
      return _routeCache[cacheKey];
    }

    // 1) Try Airlabs /flight (live data + aircraft details)
    var route = await _tryAirlabs(callsign);
    if (route != null) {
      _routeCache[cacheKey] = route;
      return route;
    }

    // 2) Try Airlabs /routes (static route database)
    route = await _tryAirlabsRoutes(callsign);
    if (route != null) {
      _routeCache[cacheKey] = route;
      return route;
    }

    // All methods failed — return "Unknown" so UI shows something
    final unknown = FlightRouteInfo(
      callsign: callsign.trim(),
      departureAirport: 'Unknown',
      arrivalAirport: 'Unknown',
      source: 'none',
    );
    _routeCache[cacheKey] = unknown;
    return unknown;
  }

  /// Try Airlabs.co — best source for live flight route data.
  /// Returns dep/arr airports with city names, delays, and status.
  Future<FlightRouteInfo?> _tryAirlabs(String callsign) async {
    try {
      final cs = callsign.trim();
      if (cs.isEmpty) return null;

      // Try ICAO callsign first
      var flight = await _airlabs.getFlightByCallsign(cs);

      // If not found, try converting to IATA and search again
      if (flight == null) {
        final airline = resolveAirline(cs);
        if (airline != null && cs.length > 3) {
          final iataFlight = '${airline.iata}${cs.substring(3)}';
          flight = await _airlabs.getFlightByIata(iataFlight);
        }
      }

      if (flight != null && flight.hasRoute) {
        return FlightRouteInfo(
          callsign: cs,
          departureAirport: flight.depIcao ?? '',
          arrivalAirport: flight.arrIcao ?? '',
          operatorIata: flight.airlineIata,
          flightNumber: flight.flightIata,
          source: 'airlabs',
          status: flight.status,
          depDelay: flight.depDelayed,
          arrDelay: flight.arrDelayed,
          scheduledDep: flight.depTime,
          scheduledArr: flight.arrTime,
          actualDep: flight.depEstimated ?? flight.depActual,
          actualArr: flight.arrEstimated ?? flight.arrActual,
          // Extra details from /flight endpoint
          depTerminal: flight.depTerminal,
          depGate: flight.depGate,
          arrTerminal: flight.arrTerminal,
          arrGate: flight.arrGate,
          arrBaggage: flight.arrBaggage,
          duration: flight.duration,
          aircraftModel: flight.model,
          aircraftManufacturer: flight.manufacturer,
          aircraftAge: flight.age,
          aircraftBuilt: flight.built,
          engineType: flight.engine,
          // Airlabs `engines_count` arrives as a string; parse it so
          // FlightRouteInfo can carry a typed int. Null when missing
          // or unparseable — the UI hides the tag in either case.
          engineCount: int.tryParse(flight.engineCount ?? ''),
          msn: flight.msn,
        );
      }
      return null;
    } catch (e) {
      debugPrint('[FlightInfo] Airlabs failed: $e');
      return null;
    }
  }

  /// Try Airlabs Routes DB — static schedule data, always has DEP/ARR if the
  /// flight exists in the database. Great fallback when /flight returns nothing.
  Future<FlightRouteInfo?> _tryAirlabsRoutes(String callsign) async {
    try {
      final cs = callsign.trim();
      if (cs.isEmpty) return null;

      // Try ICAO callsign first
      final airline = resolveAirline(cs);
      final String flightIcao = cs;
      String? flightIata;
      if (airline != null && cs.length > 3) {
        flightIata = '${airline.iata}${cs.substring(3)}';
      }

      // Try by flight_icao
      var url = AppConfig.routesUrl(flightIcao: flightIcao);
      debugPrint('[Airlabs Routes] Trying: $flightIcao');
      var response = await _dio.get(url);

      // If no result with ICAO, try IATA
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        var routes = data[ApiJsonKeys.response] as List?;

        if ((routes == null || routes.isEmpty) && flightIata != null) {
          url = AppConfig.routesUrl(flightIata: flightIata);
          debugPrint('[Airlabs Routes] Trying IATA: $flightIata');
          response = await _dio.get(url);
          if (response.statusCode == 200 && response.data is Map) {
            routes = (response.data as Map)[ApiJsonKeys.response] as List?;
          }
        }

        if (routes != null && routes.isNotEmpty) {
          final r = routes.first as Map;
          final dep = r[ApiJsonKeys.depIcao]?.toString();
          final arr = r[ApiJsonKeys.arrIcao]?.toString();

          if (dep != null && arr != null) {
            debugPrint('[Airlabs Routes] Found: $dep -> $arr');
            return FlightRouteInfo(
              callsign: cs,
              departureAirport: dep,
              arrivalAirport: arr,
              operatorIata: r[ApiJsonKeys.airlineIata]?.toString(),
              flightNumber: r[ApiJsonKeys.flightIata]?.toString(),
              source: 'airlabs_routes',
              scheduledDep: r[ApiJsonKeys.depTime]?.toString(),
              scheduledArr: r[ApiJsonKeys.arrTime]?.toString(),
              duration: r[ApiJsonKeys.duration] as int?,
            );
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('[Airlabs Routes] Error: $e');
      return null;
    }
  }

  // ignore: unused_element
  Future<FlightRouteInfo?> _tryRoutesEndpoint(String callsign) async {
    try {
      final cs = callsign.trim();
      if (cs.isEmpty) return null;

      final url = '${AppConfig.openSkyUrl}/api/routes?callsign=$cs';
      debugPrint('[FlightInfo] Trying /routes: $url');
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        // Check if proxy returned a cached 404
        if (data is Map && data['route'] == null) return null;
        final route = data['route'] as List?;
        if (route != null && route.length >= 2) {
          return FlightRouteInfo(
            callsign: cs,
            departureAirport: route.first?.toString() ?? '',
            arrivalAirport: route.last?.toString() ?? '',
            operatorIata: data['operatorIata']?.toString(),
            flightNumber: data['flightNumber']?.toString(),
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('[FlightInfo] /routes failed: $e');
      return null;
    }
  }

  /// Fallback 2: use /api/tracks to get the live flight track.
  /// The first waypoint is typically near the departure airport.
  /// We can match it against known airport positions.
  // ignore: unused_element
  Future<FlightRouteInfo?> _tryTracksEndpoint(
    String icao24,
    String callsign,
  ) async {
    try {
      final hex = icao24.trim().toLowerCase();
      // time=0 means "get the current live track"
      final url = '${AppConfig.openSkyUrl}/api/tracks/all?icao24=$hex&time=0';
      debugPrint('[FlightInfo] Trying /tracks: $url');
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        // Check for proxy-cached 404
        if (data.containsKey(ApiJsonKeys.status) &&
            data[ApiJsonKeys.status] == 404) {
          return null;
        }
        final path = data['path'] as List?;
        if (path != null && path.isNotEmpty) {
          // First waypoint = near departure
          final firstWp = path.first as List;
          // Last waypoint = current position (not arrival)
          // We have departure info but not arrival from tracks alone
          final startLat = (firstWp[1] as num?)?.toDouble();
          final startLon = (firstWp[2] as num?)?.toDouble();

          if (startLat != null && startLon != null) {
            // Find nearest airport to the first waypoint
            final dep = _findNearestAirport(startLat, startLon);
            if (dep != null) {
              return FlightRouteInfo(
                callsign: callsign.trim(),
                departureAirport: dep,
                arrivalAirport: '', // Unknown from tracks
                source: 'tracks',
              );
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('[FlightInfo] /tracks failed: $e');
      return null;
    }
  }

  /// Find the nearest known airport ICAO code to a given lat/lon.
  /// Uses a simple brute-force search over the built-in database.
  static String? _findNearestAirport(double lat, double lon) {
    // Import would create circular dep, so we use a simple inline list
    // of major airports with coordinates
    const airports = <String, List<double>>{
      'EDDF': [50.033, 8.571],
      'EDDM': [48.354, 11.786],
      'EDDB': [52.362, 13.509],
      'EDDL': [51.290, 6.767],
      'EDDH': [53.630, 9.988],
      'EDDS': [48.690, 9.222],
      'EDDK': [50.866, 7.143],
      'DTTA': [36.851, 10.227],
      'DTMB': [35.758, 10.755],
      'DTNH': [36.076, 10.438],
      'DTTJ': [33.875, 10.775],
      'GMMN': [33.367, -7.590],
      'GMMX': [31.607, -8.036],
      'GMFF': [33.927, -4.978],
      'GMAD': [30.325, -9.413],
      'GMTN': [35.727, -5.917],
      'LFPG': [49.010, 2.548],
      'LFPO': [48.723, 2.379],
      'LFML': [43.436, 5.215],
      'LFLL': [45.726, 5.091],
      'LFBO': [43.629, 1.364],
      'LFMN': [43.658, 7.216],
      'EGLL': [51.470, -0.454],
      'EGKK': [51.148, -0.190],
      'EGCC': [53.354, -2.275],
      'LTFM': [41.262, 28.742],
      'LTFJ': [40.899, 29.309],
      'LTAI': [36.899, 30.800],
      'EHAM': [52.309, 4.764],
      'EBBR': [50.902, 4.485],
      'LSZH': [47.458, 8.548],
      'LSGG': [46.238, 6.109],
      'LOWW': [48.110, 16.570],
      'LEMD': [40.472, -3.561],
      'LEBL': [41.297, 2.079],
      'LEPA': [39.552, 2.739],
      'LIRF': [41.800, 12.239],
      'LIMC': [45.630, 8.723],
      'LIPZ': [45.505, 12.352],
      'LPPT': [38.774, -9.134],
      'LGAV': [37.936, 23.944],
      'EIDW': [53.421, -6.270],
      'EPWA': [52.166, 20.967],
      'EKCH': [55.618, 12.656],
      'ENGM': [60.194, 11.100],
      'ESSA': [59.652, 17.919],
      'EFHK': [60.317, 24.963],
      'OMDB': [25.253, 55.366],
      'OTHH': [25.261, 51.565],
      'HECA': [30.122, 31.406],
      'DAAG': [36.691, 3.215],
      'HAAB': [8.978, 38.799],
      'FAOR': [-26.134, 28.242],
      'KJFK': [40.640, -73.779],
      'KLAX': [33.943, -118.408],
      'KORD': [41.978, -87.905],
      'KATL': [33.637, -84.428],
      'KMIA': [25.796, -80.287],
      'KIAD': [38.944, -77.456],
      'VHHH': [22.309, 113.915],
      'ZBAA': [40.080, 116.584],
      'RJTT': [35.553, 139.780],
      'RKSI': [37.463, 126.441],
      'WSSS': [1.350, 103.994],
      'VTBS': [13.681, 100.747],
      'VIDP': [28.556, 77.100],
      'CYYZ': [43.677, -79.631],
      'YSSY': [-33.947, 151.177],
      'SBGR': [-23.432, -46.470],
      'LHBP': [47.439, 19.262],
      'LKPR': [50.101, 14.260],
      'LROP': [44.572, 26.085],
      'UUEE': [55.973, 37.414],
      'LLBG': [32.011, 34.887],
      'OEJN': [21.680, 39.157],
      'FIMP': [-20.430, 57.684],
      'BIKF': [63.985, -22.606],
    };

    String? nearest;
    double minDist = 50.0; // Max 50km radius to match

    for (final entry in airports.entries) {
      final dlat = lat - entry.value[0];
      final dlon = lon - entry.value[1];
      // Simple euclidean approximation (good enough for matching)
      final dist = dlat * dlat + dlon * dlon;
      if (dist < minDist) {
        minDist = dist;
        nearest = entry.key;
      }
    }

    return nearest;
  }

  /// Fallback 3: use /api/flights/aircraft to find recent flights.
  /// Searches in 2-day blocks going back up to 7 days.
  /// Prefers flights with the same callsign.
  // ignore: unused_element
  Future<FlightRouteInfo?> _tryFlightsAircraftEndpoint(
    String icao24,
    String callsign,
  ) async {
    final hex = icao24.trim().toLowerCase();
    final cs = callsign.trim().toUpperCase();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Search in 2-day blocks (API max), going back up to 7 days
    // Try most recent first, then go further back
    for (int daysBack = 0; daysBack < 7; daysBack += 2) {
      try {
        final end = now - (daysBack * 86400);
        final begin = end - 172800; // 2 days

        final url =
            '${AppConfig.openSkyUrl}/api/flights/aircraft?icao24=$hex&begin=$begin&end=$end';
        debugPrint(
          '[FlightInfo] Trying /flights/aircraft (${daysBack}d back): $url',
        );
        final response = await _dio.get(url);

        if (response.statusCode == 200 && response.data is List) {
          final flights = (response.data as List).cast<Map<String, dynamic>>();
          if (flights.isEmpty) continue;

          // Prefer flights with matching callsign
          Map<String, dynamic>? best;
          for (final f in flights.reversed) {
            final fCs = (f['callsign'] as String?)?.trim().toUpperCase() ?? '';
            if (fCs == cs || cs.startsWith(fCs) || fCs.startsWith(cs)) {
              best = f;
              break;
            }
          }
          // If no callsign match, use the most recent flight
          best ??= flights.last;

          final dep = best['estDepartureAirport']?.toString();
          final arr = best['estArrivalAirport']?.toString();

          if ((dep != null && dep.isNotEmpty) ||
              (arr != null && arr.isNotEmpty)) {
            return FlightRouteInfo(
              callsign: cs,
              departureAirport: dep ?? '',
              arrivalAirport: arr ?? '',
              source: 'flights/aircraft',
            );
          }
        }

        // 404 = no flights in this window, try further back
        if (response.statusCode == 404) continue;
      } catch (e) {
        debugPrint('[FlightInfo] /flights/aircraft failed (${daysBack}d): $e');
      }
    }

    return null;
  }

  /// Get aircraft metadata from hexdb.io by ICAO24 hex code
  Future<AircraftMetadata?> getAircraftByIcao24(String icao24) async {
    try {
      final hex = icao24.trim().toLowerCase();
      if (hex.isEmpty) return null;

      // hexdb.io is a free aircraft database
      final url = '${AppConfig.hexdbUrl}/$hex';
      debugPrint('[FlightInfo] Fetching aircraft: $url');

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        return AircraftMetadata(
          icao24: hex,
          registration: data['Registration']?.toString(),
          manufacturer: data['Manufacturer']?.toString(),
          model: data['Type']?.toString(),
          typecode: data['ICAOTypeCode']?.toString(),
          operatorName: data['RegisteredOwners']?.toString(),
          operatorIcao: data['OperatorFlagCode']?.toString(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('[FlightInfo] Aircraft error: $e');
      return null;
    }
  }

  /// Resolve airline info from ICAO 3-letter code (first 3 chars of callsign).
  /// Delegates to the central airline database.
  AirlineInfo? resolveAirline(String? callsign) =>
      airline_db.resolveAirline(callsign);

  /// Airlines with valid IATA codes for search autocomplete.
  static List<AirlineInfo> get staticAirlineList =>
      airline_db.searchableAirlineList;

  static String? getAirlineLogoUrl(String? iataCode) {
    if (iataCode == null || iataCode.isEmpty) return null;
    return 'https://pics.avs.io/200/80/${iataCode.toUpperCase()}.png';
  }

  // Cache for aircraft photo URLs
  static final Map<String, String?> _photoCache = {};

  /// Get real aircraft photo URL from Planespotters.net by ICAO24 hex.
  /// On web, uses the proxy to avoid CORS issues.
  static Future<String?> getAircraftPhotoUrl(String icao24) async {
    final hex = icao24.trim().toUpperCase();
    if (hex.isEmpty) return null;
    if (_photoCache.containsKey(hex)) return _photoCache[hex];

    try {
      final dio = AppHttpClient.create(
        connectTimeout: AppConfig.shortTimeout,
        receiveTimeout: AppConfig.shortTimeout,
      );
      final url = AppConfig.photoLookupUrl(hex);
      debugPrint('[Photo] Fetching: $hex');
      final response = await dio.get(url);

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        // Handle proxy-cached 404
        if (data.containsKey('route') && data['route'] == null) {
          _photoCache[hex] = null;
          return null;
        }
        final photos = data['photos'] as List?;
        if (photos != null && photos.isNotEmpty) {
          final photo = photos.first as Map?;
          final thumb = photo?['thumbnail_large'] as Map?;
          var src = thumb?['src']?.toString();
          // On web, proxy the image URL to avoid CORS on the image itself
          if (src != null) {
            src = AppConfig.imageProxyUrl(src);
          }
          _photoCache[hex] = src;
          debugPrint('[Photo] Found: $src');
          return src;
        }
      }
      _photoCache[hex] = null;
      return null;
    } catch (e) {
      debugPrint('[Photo] Error: $e');
      _photoCache[hex] = null;
      return null;
    }
  }
}

class FlightRouteInfo {
  final String callsign;
  final String departureAirport;
  final String arrivalAirport;
  final String? operatorIata;
  final String? flightNumber;
  final String
  source; // 'airlabs', 'routes', 'tracks', 'flights/aircraft', 'none'

  // Extended fields from Airlabs
  final String? depCity, arrCity;
  final String? depName, arrName;
  final String? status; // scheduled, en-route, landed, cancelled
  final int? depDelay, arrDelay;
  final String? scheduledDep, scheduledArr;
  final String? actualDep, actualArr;
  // Gate/terminal info
  final String? depTerminal, depGate;
  final String? arrTerminal, arrGate, arrBaggage;
  final int? duration; // minutes
  // Aircraft details from Airlabs /flight endpoint
  final String? aircraftModel, aircraftManufacturer;
  final String? engineType;
  final int? aircraftAge, aircraftBuilt;
  /// Number of engines on the airframe (e.g. 2 for an A320, 4 for an
  /// A380). Mirrors airwatch-web's `metadata.engineCount` (commit
  /// d99d3c2 pt.4). Populated from the Airlabs `/aircraft.engines_count`
  /// field. May be null when the upstream entry is incomplete.
  final int? engineCount;
  /// Construction / serial number — the manufacturer's MSN (e.g.
  /// Airbus s/n 12345). Useful for spotters tracking a specific
  /// airframe across registrations.
  final String? msn;

  FlightRouteInfo({
    required this.callsign,
    required this.departureAirport,
    required this.arrivalAirport,
    this.operatorIata,
    this.flightNumber,
    this.source = 'routes',
    this.depCity,
    this.arrCity,
    this.depName,
    this.arrName,
    this.status,
    this.depDelay,
    this.arrDelay,
    this.scheduledDep,
    this.scheduledArr,
    this.actualDep,
    this.actualArr,
    this.depTerminal,
    this.depGate,
    this.arrTerminal,
    this.arrGate,
    this.arrBaggage,
    this.duration,
    this.aircraftModel,
    this.aircraftManufacturer,
    this.engineType,
    this.aircraftAge,
    this.aircraftBuilt,
    this.engineCount,
    this.msn,
  });

  bool get hasDepDelay => depDelay != null && depDelay! > 0;
  bool get hasArrDelay => arrDelay != null && arrDelay! > 0;
  bool get fromAirlabs => source == 'airlabs';
}

class AircraftMetadata {
  final String icao24;
  final String? registration;
  final String? manufacturer;
  final String? model;
  final String? typecode;
  final String? operatorName;
  final String? operatorIcao;

  AircraftMetadata({
    required this.icao24,
    this.registration,
    this.manufacturer,
    this.model,
    this.typecode,
    this.operatorName,
    this.operatorIcao,
  });

  String get displayType {
    if (manufacturer != null && model != null) {
      return '$manufacturer $model';
    }
    return model ?? typecode ?? 'Unknown';
  }
}
