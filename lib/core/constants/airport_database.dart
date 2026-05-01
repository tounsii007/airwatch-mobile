import 'package:dio/dio.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';
import 'package:airwatch_mobile/core/utils/text_normalizer.dart';

import 'airport_full_database.dart';

/// Airport database: uses the full airport database first,
/// falls back to the handwritten DB, then dynamic API lookup.
class AirportDatabase {
  static final Map<String, _Airport> _dynamicCache = {};
  static final Set<String> _lookupFailed = {};

  /// Known wrong ICAO codes from API providers → correct ICAO codes.
  static const _icaoAliases = <String, String>{
    'LICI': 'LICJ', // Palermo — Airlabs uses wrong code
  };
  static final Dio _dio = AppHttpClient.create(
    connectTimeout: AppConfig.shortTimeout,
    receiveTimeout: AppConfig.shortTimeout,
  );

  static String _normalizeText(String value) {
    return TextNormalizer.fixMojibake(value);
  }

  static String _normalizeIata(String value) {
    final cleaned =
        value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleaned.length < 2 || cleaned.length > 3) {
      return '';
    }
    return cleaned;
  }

  static _Airport _normalizeAirport(_Airport airport) {
    return _Airport(
      _normalizeIata(airport.iata),
      _normalizeText(airport.name),
      _normalizeText(airport.city),
      _normalizeText(airport.country),
      lat: airport.lat,
      lon: airport.lon,
      isMajor: airport.isMajor,
    );
  }

  static _Airport? _lookup(String? icao) {
    if (icao == null || icao.isEmpty) return null;
    final key = _icaoAliases[icao.toUpperCase()] ?? icao.toUpperCase();

    final curatedEntry = _airports[key];
    if (curatedEntry != null) {
      return _normalizeAirport(curatedEntry);
    }

    final fullEntry = lookupAirport(key);
    if (fullEntry != null) {
      return _normalizeAirport(
        _Airport(
          fullEntry.iata,
          fullEntry.name,
          fullEntry.city,
          fullEntry.country,
          lat: fullEntry.lat,
          lon: fullEntry.lon,
        ),
      );
    }

    final dynamicEntry = _dynamicCache[key];
    return dynamicEntry == null ? null : _normalizeAirport(dynamicEntry);
  }

  static String getName(String? icao) =>
      _lookup(icao)?.name ?? icao?.toUpperCase() ?? 'Unknown';

  static String getCity(String? icao) => _lookup(icao)?.city ?? '';

  static String getCountry(String? icao) => _lookup(icao)?.country ?? '';

  static String getIata(String? icao) => _lookup(icao)?.iata ?? '';

  static double? getLat(String? icao) => _lookup(icao)?.lat;
  static double? getLon(String? icao) => _lookup(icao)?.lon;

  static String displayCode(String? icao) {
    if (icao == null || icao.isEmpty) return '???';
    final apt = _lookup(icao);
    if (apt != null) return apt.iata.isNotEmpty ? apt.iata : icao.toUpperCase();
    _fetchIfNeeded(icao);
    return icao.toUpperCase();
  }

  static String fullDisplay(String? icao) {
    if (icao == null || icao.isEmpty) return 'Unknown Airport';
    final apt = _lookup(icao);
    if (apt != null) {
      final code = apt.iata.isNotEmpty ? apt.iata : icao.toUpperCase();
      return '${apt.city} ($code)';
    }
    _fetchIfNeeded(icao);
    return icao.toUpperCase();
  }

  static bool hasData(String? icao) {
    if (icao == null) return false;
    if (_lookup(icao) != null) return true;
    _fetchIfNeeded(icao);
    return false;
  }

  static List<MajorAirport> getMajorAirports() {
    return _airports.entries
        .where((e) => e.value.lat != null && e.value.isMajor)
        .map(
          (e) => MajorAirport(
            icao: e.key,
            iata: e.value.iata,
            name: _normalizeText(e.value.name),
            city: _normalizeText(e.value.city),
            country: e.value.country,
            lat: e.value.lat!,
            lon: e.value.lon!,
          ),
        )
        .toList();
  }

  static Future<void> _fetchIfNeeded(String icao) async {
    final key = _icaoAliases[icao.toUpperCase()] ?? icao.toUpperCase();
    if (_airports.containsKey(key) ||
        _dynamicCache.containsKey(key) ||
        _lookupFailed.contains(key) ||
        lookupAirport(key) != null) {
      return;
    }
    try {
      final url = '${AppConfig.airportLookupUrl}/$key';
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data is Map) {
        final d = response.data as Map;
        _dynamicCache[key] = _normalizeAirport(
          _Airport(
            d['iata']?.toString() ?? '',
            d['airport']?.toString() ?? key,
            d['region_name']?.toString() ?? '',
            d['country_code']?.toString() ?? '',
            lat: (d['latitude'] as num?)?.toDouble(),
            lon: (d['longitude'] as num?)?.toDouble(),
          ),
        );
      } else {
        _lookupFailed.add(key);
      }
    } catch (_) {
      _lookupFailed.add(key);
    }
  }

  static Future<void> prefetch(List<String> codes) async {
    final toFetch = codes
        .where(
          (c) =>
              c.isNotEmpty &&
              !_airports.containsKey(c.toUpperCase()) &&
              !_dynamicCache.containsKey(c.toUpperCase()) &&
              !_lookupFailed.contains(c.toUpperCase()),
        )
        .toSet();
    await Future.wait(toFetch.map(_fetchIfNeeded));
  }
}

class MajorAirport {
  final String icao, iata, name, city, country;
  final double lat, lon;

  const MajorAirport({
    required this.icao,
    required this.iata,
    required this.name,
    required this.city,
    required this.country,
    required this.lat,
    required this.lon,
  });
}

class _Airport {
  final String iata, name, city, country;
  final double? lat, lon;
  final bool isMajor;

  const _Airport(
    this.iata,
    this.name,
    this.city,
    this.country, {
    this.lat,
    this.lon,
    this.isMajor = false,
  });
}

// Built-in curated airport database with coordinates for major airports.
const Map<String, _Airport> _airports = {
  // Tunisia
  'DTTA': _Airport('TUN', 'Tunis-Carthage International', 'Tunis', 'Tunisia', lat: 36.851, lon: 10.227, isMajor: true),
  'DTMB': _Airport('MIR', 'Habib Bourguiba International', 'Monastir', 'Tunisia', lat: 35.758, lon: 10.755),
  'DTNH': _Airport('NBE', 'Enfidha-Hammamet International', 'Enfidha', 'Tunisia', lat: 36.076, lon: 10.438),
  'DTTJ': _Airport('DJE', 'Djerba-Zarzis International', 'Djerba', 'Tunisia', lat: 33.875, lon: 10.775),
  'DTTF': _Airport('EBM', 'El Borma Airport', 'El Borma', 'Tunisia', lat: 31.704, lon: 9.255),
  'DTTG': _Airport('GAF', 'Gafsa-Ksar International', 'Gafsa', 'Tunisia', lat: 34.422, lon: 8.822),
  'DTKA': _Airport('TOE', 'Tozeur-Nefta International', 'Tozeur', 'Tunisia', lat: 33.940, lon: 8.111),
  'DTTX': _Airport('GAE', 'Gab\u00e8s-Matmata International', 'Gab\u00e8s', 'Tunisia', lat: 33.877, lon: 10.103),
  'DTTR': _Airport('TBJ', 'Tabarka-Ain Draham', 'Tabarka', 'Tunisia', lat: 36.978, lon: 8.877),
  'DTTS': _Airport('SFA', 'Sfax-Thyna International', 'Sfax', 'Tunisia', lat: 34.718, lon: 10.691),

  // Morocco
  'GMMN': _Airport('CMN', 'Mohammed V International', 'Casablanca', 'Morocco', lat: 33.367, lon: -7.590, isMajor: true),
  'GMMX': _Airport('RAK', 'Marrakech Menara', 'Marrakech', 'Morocco', lat: 31.607, lon: -8.036, isMajor: true),
  'GMFF': _Airport('FEZ', 'F\u00e8s-Sa\u00efss Airport', 'F\u00e8s', 'Morocco', lat: 33.927, lon: -4.978),
  'GMFO': _Airport('OJD', 'Angads Airport', 'Oujda', 'Morocco', lat: 34.787, lon: -1.924),
  'GMTN': _Airport('TNG', 'Ibn Battouta Airport', 'Tangier', 'Morocco', lat: 35.727, lon: -5.917),
  'GMMZ': _Airport('OZZ', 'Ouarzazate Airport', 'Ouarzazate', 'Morocco', lat: 30.939, lon: -6.909),
  'GMAD': _Airport('AGA', 'Al Massira Airport', 'Agadir', 'Morocco', lat: 30.325, lon: -9.413),
  'GMME': _Airport('RBA', 'Rabat-Sal\u00e9 Airport', 'Rabat', 'Morocco', lat: 34.051, lon: -6.751),
  'GMMW': _Airport('NDR', 'Nador International', 'Nador', 'Morocco', lat: 34.989, lon: -3.028),
  'GMMH': _Airport('OZG', 'Zagora Airport', 'Zagora', 'Morocco', lat: 30.320, lon: -5.867),
  'GMMI': _Airport('ESU', 'Mogador Airport', 'Essaouira', 'Morocco', lat: 31.398, lon: -9.682),
  'GMFK': _Airport('ERH', 'Moulay Ali Cherif', 'Errachidia', 'Morocco', lat: 31.948, lon: -4.399),
  'GMMC': _Airport('CAS', 'Anfa Airport', 'Casablanca', 'Morocco', lat: 33.553, lon: -7.661),
  'GMMB': _Airport('BEM', 'Beni Mellal Airport', 'Beni Mellal', 'Morocco', lat: 32.402, lon: -6.316),
  'GMTA': _Airport('AHU', 'Cherif Al Idrissi', 'Al Hoceima', 'Morocco', lat: 35.177, lon: -3.840),
  'GMTT': _Airport('TTU', 'Sania Ramel Airport', 'Tetouan', 'Morocco', lat: 35.594, lon: -5.320),
  'GMMJ': _Airport('VIL', 'Dakhla Airport', 'Dakhla', 'Morocco', lat: 23.713, lon: -15.932),
  'GMML': _Airport('EUN', 'Hassan I Airport', 'Laayoune', 'Morocco', lat: 27.152, lon: -13.219),

  // Germany
  'EDDF': _Airport('FRA', 'Frankfurt Airport', 'Frankfurt', 'Germany', lat: 50.033, lon: 8.571, isMajor: true),
  'EDDM': _Airport('MUC', 'Munich Airport', 'Munich', 'Germany', lat: 48.354, lon: 11.786, isMajor: true),
  'EDDB': _Airport('BER', 'Berlin Brandenburg', 'Berlin', 'Germany', lat: 52.362, lon: 13.509, isMajor: true),
  'EDDL': _Airport('DUS', 'D\u00fcsseldorf Airport', 'D\u00fcsseldorf', 'Germany', lat: 51.290, lon: 6.767),
  'EDDH': _Airport('HAM', 'Hamburg Airport', 'Hamburg', 'Germany', lat: 53.630, lon: 9.988),
  'EDDS': _Airport('STR', 'Stuttgart Airport', 'Stuttgart', 'Germany', lat: 48.690, lon: 9.222),
  'EDDK': _Airport('CGN', 'Cologne Bonn Airport', 'Cologne', 'Germany', lat: 50.866, lon: 7.143),
  'EDDP': _Airport('LEJ', 'Leipzig Airport', 'Leipzig', 'Germany', lat: 51.432, lon: 12.242),
  'EDDN': _Airport('NUE', 'Nuremberg Airport', 'Nuremberg', 'Germany', lat: 49.499, lon: 11.078),
  'EDDW': _Airport('BRE', 'Bremen Airport', 'Bremen', 'Germany', lat: 53.047, lon: 8.787),

  // France
  'LFPG': _Airport('CDG', 'Charles de Gaulle', 'Paris', 'France', lat: 49.010, lon: 2.548, isMajor: true),
  'LFPO': _Airport('ORY', 'Orly Airport', 'Paris', 'France', lat: 48.723, lon: 2.379),
  'LFML': _Airport('MRS', 'Marseille Provence', 'Marseille', 'France', lat: 43.436, lon: 5.215),
  'LFLL': _Airport('LYS', 'Lyon-Saint Exup\u00e9ry', 'Lyon', 'France', lat: 45.726, lon: 5.091),
  'LFBO': _Airport('TLS', 'Toulouse-Blagnac', 'Toulouse', 'France', lat: 43.629, lon: 1.364),
  'LFMN': _Airport('NCE', 'Nice C\u00f4te d\'Azur', 'Nice', 'France', lat: 43.658, lon: 7.216),

  // UK
  'EGLL': _Airport('LHR', 'Heathrow Airport', 'London', 'UK', lat: 51.470, lon: -0.454, isMajor: true),
  'EGKK': _Airport('LGW', 'Gatwick Airport', 'London', 'UK', lat: 51.148, lon: -0.190),
  'EGSS': _Airport('STN', 'Stansted Airport', 'London', 'UK', lat: 51.885, lon: 0.235),
  'EGGW': _Airport('LTN', 'Luton Airport', 'London', 'UK', lat: 51.875, lon: -0.368),
  'EGCC': _Airport('MAN', 'Manchester Airport', 'Manchester', 'UK', lat: 53.354, lon: -2.275),
  'EGPH': _Airport('EDI', 'Edinburgh Airport', 'Edinburgh', 'UK', lat: 55.950, lon: -3.373),

  // Turkey
  'LTFM': _Airport('IST', 'Istanbul Airport', 'Istanbul', 'Turkey', lat: 41.262, lon: 28.742, isMajor: true),
  'LTFJ': _Airport('SAW', 'Sabiha G\u00f6k\u00e7en', 'Istanbul', 'Turkey', lat: 40.899, lon: 29.309),
  'LTAI': _Airport('AYT', 'Antalya Airport', 'Antalya', 'Turkey', lat: 36.899, lon: 30.800),
  'LTAC': _Airport('ESB', 'Esenbo\u011fa Airport', 'Ankara', 'Turkey', lat: 40.128, lon: 32.995),

  // Benelux / Switzerland / Austria
  'EHAM': _Airport('AMS', 'Schiphol Airport', 'Amsterdam', 'Netherlands', lat: 52.309, lon: 4.764, isMajor: true),
  'EBBR': _Airport('BRU', 'Brussels Airport', 'Brussels', 'Belgium', lat: 50.902, lon: 4.485),
  'LSZH': _Airport('ZRH', 'Z\u00fcrich Airport', 'Z\u00fcrich', 'Switzerland', lat: 47.458, lon: 8.548, isMajor: true),
  'LSGG': _Airport('GVA', 'Geneva Airport', 'Geneva', 'Switzerland', lat: 46.238, lon: 6.109),
  'LOWW': _Airport('VIE', 'Vienna Airport', 'Vienna', 'Austria', lat: 48.110, lon: 16.570),

  // Spain
  'LEMD': _Airport('MAD', 'Madrid-Barajas', 'Madrid', 'Spain', lat: 40.472, lon: -3.561, isMajor: true),
  'LEBL': _Airport('BCN', 'El Prat Airport', 'Barcelona', 'Spain', lat: 41.297, lon: 2.079, isMajor: true),
  'LEBB': _Airport('BIO', 'Bilbao Airport', 'Bilbao', 'Spain', lat: 43.301, lon: -2.910),
  'LEPA': _Airport('PMI', 'Palma de Mallorca', 'Palma', 'Spain', lat: 39.552, lon: 2.739),
  'LEVC': _Airport('VLC', 'Valencia Airport', 'Valencia', 'Spain', lat: 39.489, lon: -0.481),
  'LEIB': _Airport('IBZ', 'Ibiza Airport', 'Ibiza', 'Spain', lat: 38.873, lon: 1.373),
  'LEMH': _Airport('MAH', 'Menorca Airport', 'Mahon', 'Spain', lat: 39.863, lon: 4.219),
  'LEMG': _Airport('AGP', 'M\u00e1laga Airport', 'M\u00e1laga', 'Spain', lat: 36.675, lon: -4.499),
  'LEAL': _Airport('ALC', 'Alicante Airport', 'Alicante', 'Spain', lat: 38.282, lon: -0.558),

  // Italy
  'LIRF': _Airport('FCO', 'Fiumicino Airport', 'Rome', 'Italy', lat: 41.800, lon: 12.239, isMajor: true),
  'LIML': _Airport('LIN', 'Linate Airport', 'Milan', 'Italy', lat: 45.445, lon: 9.277),
  'LIMC': _Airport('MXP', 'Malpensa Airport', 'Milan', 'Italy', lat: 45.630, lon: 8.723),
  'LIME': _Airport('BGY', 'Orio al Serio', 'Bergamo', 'Italy', lat: 45.669, lon: 9.704),
  'LIPZ': _Airport('VCE', 'Marco Polo Airport', 'Venice', 'Italy', lat: 45.505, lon: 12.352),
  'LIRN': _Airport('NAP', 'Naples Airport', 'Naples', 'Italy', lat: 40.886, lon: 14.291),

  // Portugal / Greece / Ireland
  'LPPT': _Airport('LIS', 'Lisbon Airport', 'Lisbon', 'Portugal', lat: 38.774, lon: -9.134, isMajor: true),
  'LPPR': _Airport('OPO', 'Porto Airport', 'Porto', 'Portugal', lat: 41.248, lon: -8.681),
  'LGAV': _Airport('ATH', 'Athens Airport', 'Athens', 'Greece', lat: 37.936, lon: 23.944, isMajor: true),
  'LGIR': _Airport('HER', 'Heraklion Airport', 'Heraklion', 'Greece', lat: 35.339, lon: 25.180),
  'LGTS': _Airport('SKG', 'Thessaloniki Airport', 'Thessaloniki', 'Greece', lat: 40.519, lon: 22.971),
  'LCLK': _Airport('LCA', 'Larnaca International', 'Larnaca', 'Cyprus', lat: 34.875, lon: 33.624),
  'LCPH': _Airport('PFO', 'Paphos International', 'Paphos', 'Cyprus', lat: 34.718, lon: 32.485),
  'EIDW': _Airport('DUB', 'Dublin Airport', 'Dublin', 'Ireland', lat: 53.421, lon: -6.270),

  // Poland / Scandinavia
  'EPWA': _Airport('WAW', 'Chopin Airport', 'Warsaw', 'Poland', lat: 52.166, lon: 20.967),
  'EPKK': _Airport('KRK', 'Krak\u00f3w Airport', 'Krak\u00f3w', 'Poland', lat: 50.078, lon: 19.785),
  'EKCH': _Airport('CPH', 'Copenhagen Airport', 'Copenhagen', 'Denmark', lat: 55.618, lon: 12.656, isMajor: true),
  'ENGM': _Airport('OSL', 'Oslo Gardermoen', 'Oslo', 'Norway', lat: 60.194, lon: 11.100),
  'ESSA': _Airport('ARN', 'Arlanda Airport', 'Stockholm', 'Sweden', lat: 59.652, lon: 17.919),
  'EFHK': _Airport('HEL', 'Helsinki-Vantaa', 'Helsinki', 'Finland', lat: 60.317, lon: 24.963),

  // Eastern Europe
  'LHBP': _Airport('BUD', 'Budapest Airport', 'Budapest', 'Hungary', lat: 47.439, lon: 19.262),
  'LKPR': _Airport('PRG', 'V\u00e1clav Havel Airport', 'Prague', 'Czech Republic', lat: 50.101, lon: 14.260),
  'LROP': _Airport('OTP', 'Henri Coand\u0103 Airport', 'Bucharest', 'Romania', lat: 44.572, lon: 26.085),
  'LYBE': _Airport('BEG', 'Belgrade Airport', 'Belgrade', 'Serbia', lat: 44.819, lon: 20.309),
  'LBSF': _Airport('SOF', 'Sofia Airport', 'Sofia', 'Bulgaria', lat: 42.696, lon: 23.411),
  'LDZA': _Airport('ZAG', 'Zagreb Airport', 'Zagreb', 'Croatia', lat: 45.743, lon: 16.069),
  'BIKF': _Airport('KEF', 'Keflav\u00edk Airport', 'Reykjavik', 'Iceland', lat: 63.985, lon: -22.606),

  // Middle East
  'OMDB': _Airport('DXB', 'Dubai International', 'Dubai', 'UAE', lat: 25.253, lon: 55.366, isMajor: true),
  'OMDW': _Airport('DWC', 'Al Maktoum Airport', 'Dubai', 'UAE', lat: 24.896, lon: 55.172),
  'OMAA': _Airport('AUH', 'Abu Dhabi Airport', 'Abu Dhabi', 'UAE', lat: 24.433, lon: 54.651),
  'OOMS': _Airport('MCT', 'Muscat International', 'Muscat', 'Oman', lat: 23.593, lon: 58.284),
  'OBBI': _Airport('BAH', 'Bahrain International', 'Manama', 'Bahrain', lat: 26.270, lon: 50.634),
  'OTHH': _Airport('DOH', 'Hamad International', 'Doha', 'Qatar', lat: 25.261, lon: 51.565, isMajor: true),
  'OJAI': _Airport('AMM', 'Queen Alia International', 'Amman', 'Jordan', lat: 31.722, lon: 35.993),
  'OKBK': _Airport('KWI', 'Kuwait International', 'Kuwait City', 'Kuwait', lat: 29.226, lon: 47.968),
  'OEJN': _Airport('JED', 'King Abdulaziz Airport', 'Jeddah', 'Saudi Arabia', lat: 21.680, lon: 39.157),
  'OERK': _Airport('RUH', 'King Khalid Airport', 'Riyadh', 'Saudi Arabia', lat: 24.958, lon: 46.699),
  'LLBG': _Airport('TLV', 'Ben Gurion Airport', 'Tel Aviv', 'Israel', lat: 32.011, lon: 34.887),

  // Africa
  'HECA': _Airport('CAI', 'Cairo Airport', 'Cairo', 'Egypt', lat: 30.122, lon: 31.406, isMajor: true),
  'HEGN': _Airport('HRG', 'Hurghada International', 'Hurghada', 'Egypt', lat: 27.178, lon: 33.799),
  'HTDA': _Airport('DAR', 'Julius Nyerere International', 'Dar es Salaam', 'Tanzania', lat: -6.878, lon: 39.202),
  'DAAG': _Airport('ALG', 'Houari Boumediene', 'Algiers', 'Algeria', lat: 36.691, lon: 3.215, isMajor: true),
  'DAUH': _Airport('OGX', 'Ain Beida Airport', 'Ouargla', 'Algeria', lat: 31.917, lon: 5.413),
  'HAAB': _Airport('ADD', 'Bole International', 'Addis Ababa', 'Ethiopia', lat: 8.978, lon: 38.799, isMajor: true),
  'FAOR': _Airport('JNB', 'OR Tambo Airport', 'Johannesburg', 'South Africa', lat: -26.134, lon: 28.242, isMajor: true),
  'FACT': _Airport('CPT', 'Cape Town Airport', 'Cape Town', 'South Africa', lat: -33.965, lon: 18.602),
  'FIMP': _Airport('MRU', 'SSR International Airport', 'Mauritius', 'Mauritius', lat: -20.430, lon: 57.684),
  'FMEE': _Airport('RUN', 'Roland Garros Airport', 'La R\u00e9union', 'France', lat: -20.887, lon: 55.510),
  'GOOY': _Airport('DSS', 'Blaise Diagne Airport', 'Dakar', 'Senegal', lat: 14.670, lon: -17.073),
  'GQNO': _Airport('NKC', 'Nouakchott-Oumtounsy', 'Nouakchott', 'Mauritania', lat: 18.310, lon: -15.969),
  'DNMM': _Airport('LOS', 'Murtala Muhammed Airport', 'Lagos', 'Nigeria', lat: 6.577, lon: 3.321),
  'HKJK': _Airport('NBO', 'Jomo Kenyatta Airport', 'Nairobi', 'Kenya', lat: -1.319, lon: 36.928),
  'HKMO': _Airport('MBA', 'Moi International', 'Mombasa', 'Kenya', lat: -4.034, lon: 39.594),
  'FALA': _Airport('HLA', 'Lanseria Airport', 'Johannesburg', 'South Africa', lat: -25.938, lon: 27.926),

  // USA
  'KJFK': _Airport('JFK', 'John F. Kennedy', 'New York', 'USA', lat: 40.640, lon: -73.779, isMajor: true),
  'KLAX': _Airport('LAX', 'Los Angeles Airport', 'Los Angeles', 'USA', lat: 33.943, lon: -118.408, isMajor: true),
  'KORD': _Airport('ORD', 'O\'Hare Airport', 'Chicago', 'USA', lat: 41.978, lon: -87.905, isMajor: true),
  'KATL': _Airport('ATL', 'Hartsfield-Jackson', 'Atlanta', 'USA', lat: 33.637, lon: -84.428, isMajor: true),
  'KDFW': _Airport('DFW', 'Dallas/Fort Worth', 'Dallas', 'USA', lat: 32.897, lon: -97.038),
  'KSFO': _Airport('SFO', 'San Francisco Airport', 'San Francisco', 'USA', lat: 37.615, lon: -122.390, isMajor: true),
  'KDEN': _Airport('DEN', 'Denver Airport', 'Denver', 'USA', lat: 39.862, lon: -104.673),
  'KMIA': _Airport('MIA', 'Miami Airport', 'Miami', 'USA', lat: 25.796, lon: -80.287),
  'KEWR': _Airport('EWR', 'Newark Airport', 'Newark', 'USA', lat: 40.693, lon: -74.169),
  'KIAD': _Airport('IAD', 'Dulles Airport', 'Washington DC', 'USA', lat: 38.944, lon: -77.456),

  // Asia
  'VHHH': _Airport('HKG', 'Hong Kong Airport', 'Hong Kong', 'China', lat: 22.309, lon: 113.915, isMajor: true),
  'ZBAA': _Airport('PEK', 'Beijing Capital', 'Beijing', 'China', lat: 40.080, lon: 116.584, isMajor: true),
  'ZGGG': _Airport('CAN', 'Guangzhou Baiyun', 'Guangzhou', 'China', lat: 23.392, lon: 113.299),
  'ZGSZ': _Airport('SZX', 'Shenzhen Baoan', 'Shenzhen', 'China', lat: 22.639, lon: 113.811),
  'ZSPD': _Airport('PVG', 'Pudong Airport', 'Shanghai', 'China', lat: 31.143, lon: 121.805),
  'RJTT': _Airport('HND', 'Haneda Airport', 'Tokyo', 'Japan', lat: 35.553, lon: 139.780, isMajor: true),
  'RJBB': _Airport('KIX', 'Kansai International', 'Osaka', 'Japan', lat: 34.434, lon: 135.244),
  'RJCC': _Airport('CTS', 'New Chitose Airport', 'Sapporo', 'Japan', lat: 42.775, lon: 141.692),
  'RJAA': _Airport('NRT', 'Narita Airport', 'Tokyo', 'Japan', lat: 35.765, lon: 140.386),
  'RKSI': _Airport('ICN', 'Incheon Airport', 'Seoul', 'South Korea', lat: 37.463, lon: 126.441, isMajor: true),
  'WSSS': _Airport('SIN', 'Changi Airport', 'Singapore', 'Singapore', lat: 1.350, lon: 103.994, isMajor: true),
  'VTBS': _Airport('BKK', 'Suvarnabhumi Airport', 'Bangkok', 'Thailand', lat: 13.681, lon: 100.747, isMajor: true),
  'VIDP': _Airport('DEL', 'Indira Gandhi Airport', 'Delhi', 'India', lat: 28.556, lon: 77.100, isMajor: true),
  'VOCI': _Airport('COK', 'Cochin International', 'Kochi', 'India', lat: 10.152, lon: 76.401),
  'VABB': _Airport('BOM', 'Chhatrapati Shivaji', 'Mumbai', 'India', lat: 19.089, lon: 72.868),
  'WMKK': _Airport('KUL', 'Kuala Lumpur Airport', 'Kuala Lumpur', 'Malaysia', lat: 2.746, lon: 101.710),
  'WIII': _Airport('CGK', 'Soekarno-Hatta', 'Jakarta', 'Indonesia', lat: -6.126, lon: 106.656),
  'RCTP': _Airport('TPE', 'Taoyuan Airport', 'Taipei', 'Taiwan', lat: 25.077, lon: 121.233),

  // Canada / Australia
  'CYYZ': _Airport('YYZ', 'Pearson Airport', 'Toronto', 'Canada', lat: 43.677, lon: -79.631, isMajor: true),
  'CYUL': _Airport('YUL', 'Montr\u00e9al-Trudeau', 'Montr\u00e9al', 'Canada', lat: 45.470, lon: -73.741),
  'CYVR': _Airport('YVR', 'Vancouver Airport', 'Vancouver', 'Canada', lat: 49.195, lon: -123.179),
  'CYYC': _Airport('YYC', 'Calgary International', 'Calgary', 'Canada', lat: 51.113, lon: -114.020),
  'CYEG': _Airport('YEG', 'Edmonton International', 'Edmonton', 'Canada', lat: 53.309, lon: -113.580),
  'YSSY': _Airport('SYD', 'Sydney Airport', 'Sydney', 'Australia', lat: -33.947, lon: 151.177, isMajor: true),
  'YMML': _Airport('MEL', 'Melbourne Airport', 'Melbourne', 'Australia', lat: -37.669, lon: 144.843),

  // South America
  'SBGR': _Airport('GRU', 'Guarulhos Airport', 'S\u00e3o Paulo', 'Brazil', lat: -23.432, lon: -46.470, isMajor: true),
  'SAEZ': _Airport('EZE', 'Ezeiza Airport', 'Buenos Aires', 'Argentina', lat: -34.822, lon: -58.536),
  'SABE': _Airport('AEP', 'Aeroparque', 'Buenos Aires', 'Argentina', lat: -34.559, lon: -58.416),
  'SUMU': _Airport('MVD', 'Carrasco Airport', 'Montevideo', 'Uruguay', lat: -34.838, lon: -56.031),
  'SCEL': _Airport('SCL', 'Arturo Merino Ben\u00edtez', 'Santiago', 'Chile', lat: -33.393, lon: -70.786),
  'SKBO': _Airport('BOG', 'El Dorado Airport', 'Bogot\u00e1', 'Colombia', lat: 4.702, lon: -74.147),

  // Russia
  'UUEE': _Airport('SVO', 'Sheremetyevo', 'Moscow', 'Russia', lat: 55.973, lon: 37.414, isMajor: true),
  'UUDD': _Airport('DME', 'Domodedovo', 'Moscow', 'Russia', lat: 55.408, lon: 37.906),
};
