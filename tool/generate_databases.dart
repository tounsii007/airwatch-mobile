import 'dart:convert';
import 'dart:io';

/// Generates airline_database.dart and airport_full_database.dart
/// from Airlabs JSON data.

/// Airports named after persons — map IATA code to actual city name
const _knownCities = <String, String>{
  'JFK': 'New York', 'EWR': 'Newark', 'LGA': 'New York',
  'CDG': 'Paris', 'ORY': 'Paris',
  'FCO': 'Rome', 'CIA': 'Rome',
  'MAD': 'Madrid',
  'LHR': 'London', 'LGW': 'London', 'STN': 'London', 'LTN': 'London', 'LCY': 'London',
  'IST': 'Istanbul', 'SAW': 'Istanbul',
  'AMM': 'Amman',
  'RUH': 'Riyadh', 'JED': 'Jeddah', 'MED': 'Medina',
  'NBO': 'Nairobi', 'MBA': 'Mombasa',
  'ZNZ': 'Zanzibar', 'DAR': 'Dar es Salaam',
  'ADD': 'Addis Ababa',
  'CMN': 'Casablanca', 'RAK': 'Marrakech',
  'ALG': 'Algiers', 'ORN': 'Oran', 'CZL': 'Constantine',
  'TUN': 'Tunis', 'MIR': 'Monastir', 'NBE': 'Enfidha', 'DJE': 'Djerba', 'SFA': 'Sfax',
  'CAI': 'Cairo', 'HRG': 'Hurghada', 'SSH': 'Sharm El Sheikh',
  'DXB': 'Dubai', 'AUH': 'Abu Dhabi', 'SHJ': 'Sharjah',
  'DOH': 'Doha',
  'BAH': 'Bahrain',
  'KWI': 'Kuwait',
  'MCT': 'Muscat',
  'TLV': 'Tel Aviv',
  'DEL': 'Delhi', 'BOM': 'Mumbai', 'BLR': 'Bangalore', 'MAA': 'Chennai', 'CCU': 'Kolkata',
  'PEK': 'Beijing', 'PVG': 'Shanghai', 'CAN': 'Guangzhou', 'HKG': 'Hong Kong',
  'NRT': 'Tokyo', 'HND': 'Tokyo', 'KIX': 'Osaka',
  'ICN': 'Seoul', 'GMP': 'Seoul',
  'SIN': 'Singapore',
  'BKK': 'Bangkok', 'DMK': 'Bangkok',
  'KUL': 'Kuala Lumpur',
  'CGK': 'Jakarta',
  'MNL': 'Manila',
  'SGN': 'Ho Chi Minh', 'HAN': 'Hanoi',
  'SYD': 'Sydney', 'MEL': 'Melbourne', 'BNE': 'Brisbane',
  'AKL': 'Auckland',
  'GRU': 'São Paulo', 'GIG': 'Rio de Janeiro',
  'EZE': 'Buenos Aires', 'AEP': 'Buenos Aires',
  'BOG': 'Bogotá', 'SCL': 'Santiago', 'LIM': 'Lima',
  'MEX': 'Mexico City', 'CUN': 'Cancún',
  'ATL': 'Atlanta', 'ORD': 'Chicago', 'LAX': 'Los Angeles',
  'DFW': 'Dallas', 'DEN': 'Denver', 'SFO': 'San Francisco',
  'MIA': 'Miami', 'SEA': 'Seattle', 'BOS': 'Boston',
  'IAD': 'Washington', 'DCA': 'Washington',
  'IAH': 'Houston', 'MSP': 'Minneapolis', 'DTW': 'Detroit',
  'PHL': 'Philadelphia', 'CLT': 'Charlotte', 'PHX': 'Phoenix',
  'LAS': 'Las Vegas', 'MCO': 'Orlando', 'SAN': 'San Diego',
  'YYZ': 'Toronto', 'YUL': 'Montreal', 'YVR': 'Vancouver',
  'FRA': 'Frankfurt', 'MUC': 'Munich', 'BER': 'Berlin',
  'DUS': 'Düsseldorf', 'HAM': 'Hamburg', 'STR': 'Stuttgart',
  'CGN': 'Cologne', 'NUE': 'Nuremberg',
  'ZRH': 'Zürich', 'GVA': 'Geneva', 'BSL': 'Basel',
  'VIE': 'Vienna',
  'AMS': 'Amsterdam',
  'BRU': 'Brussels',
  'CPH': 'Copenhagen',
  'OSL': 'Oslo', 'BGO': 'Bergen',
  'ARN': 'Stockholm', 'GOT': 'Gothenburg',
  'HEL': 'Helsinki',
  'DUB': 'Dublin',
  'LIS': 'Lisbon', 'OPO': 'Porto', 'FAO': 'Faro',
  'ATH': 'Athens', 'SKG': 'Thessaloniki', 'HER': 'Heraklion',
  'BCN': 'Barcelona', 'PMI': 'Palma', 'AGP': 'Malaga', 'ALC': 'Alicante',
  'MXP': 'Milan', 'BGY': 'Bergamo', 'VCE': 'Venice', 'NAP': 'Naples',
  'WAW': 'Warsaw', 'KRK': 'Krakow',
  'PRG': 'Prague',
  'BUD': 'Budapest',
  'OTP': 'Bucharest',
  'SOF': 'Sofia',
  'BEG': 'Belgrade',
  'ZAG': 'Zagreb',
  'TIA': 'Tirana',
  'SKP': 'Skopje',
  'SJJ': 'Sarajevo',
  'KEF': 'Reykjavik',
  'SVO': 'Moscow', 'DME': 'Moscow', 'LED': 'St. Petersburg',
  'AYT': 'Antalya', 'ESB': 'Ankara', 'ADB': 'Izmir',
  'CPT': 'Cape Town', 'JNB': 'Johannesburg',
  'MRU': 'Mauritius',
  'DSS': 'Dakar',
  'LOS': 'Lagos', 'ABV': 'Abuja',
  'ACC': 'Accra',
  'DPS': 'Bali', 'HKT': 'Phuket', 'USM': 'Koh Samui',
  'MLE': 'Malé', 'CMB': 'Colombo',
  'KTM': 'Kathmandu',
  'TPE': 'Taipei', 'TSA': 'Taipei', 'KHH': 'Kaohsiung',
  'DMM': 'Dammam', 'TIF': 'Taif', 'AHB': 'Abha',
  'PKX': 'Beijing',  'SHA': 'Shanghai', 'SZX': 'Shenzhen',
  'CTU': 'Chengdu', 'CKG': 'Chongqing', 'WUH': 'Wuhan', 'XIY': 'Xian',
  'FUK': 'Fukuoka', 'CTS': 'Sapporo', 'NGO': 'Nagoya',
  'PUS': 'Busan',
  'CGP': 'Chittagong', 'DAC': 'Dhaka',
  'ISB': 'Islamabad', 'KHI': 'Karachi', 'LHE': 'Lahore',
  'RGN': 'Yangon', 'MDL': 'Mandalay',
  'CEB': 'Cebu', 'DVO': 'Davao',
  'SUB': 'Surabaya', 'UPG': 'Makassar',
  'PNH': 'Phnom Penh', 'REP': 'Siem Reap',
};
///
/// Usage: dart run tool/generate_databases.dart
void main() async {
  await generateAirlines();
  await generateAirports();
}

void _log(String message) {
  stdout.writeln(message);
}

void _logError(String message) {
  stderr.writeln(message);
}

Future<void> generateAirlines() async {
  final file = File('proxy/cache/airlines_raw.json');
  if (!await file.exists()) {
    _logError('airlines_raw.json not found');
    return;
  }

  final data = jsonDecode(await file.readAsString());
  final airlines = data['response'] as List;

  final buf = StringBuffer();
  buf.writeln('/// Auto-generated airline database from Airlabs API.');
  buf.writeln('/// ${airlines.length} airlines total.');
  buf.writeln('/// Generated: ${DateTime.now().toIso8601String()}');
  buf.writeln();
  buf.writeln('class AirlineInfo {');
  buf.writeln('  final String icao, iata, name, country;');
  buf.writeln('  const AirlineInfo({required this.icao, required this.iata,');
  buf.writeln('      required this.name, required this.country});');
  buf.writeln('}');
  buf.writeln();
  buf.writeln('AirlineInfo? resolveAirline(String? callsign) {');
  buf.writeln('  if (callsign == null || callsign.trim().length < 3) return null;');
  buf.writeln('  return airlineDatabase[callsign.trim().substring(0, 3).toUpperCase()];');
  buf.writeln('}');
  buf.writeln();
  buf.writeln('List<AirlineInfo> get airlineList => airlineDatabase.values.toList();');
  buf.writeln();
  buf.writeln('const Map<String, AirlineInfo> airlineDatabase = {');

  int count = 0;
  final seen = <String>{};
  for (final a in airlines) {
    final icao = a['icao_code']?.toString() ?? '';
    final iata = a['iata_code']?.toString() ?? '';
    final name = (a['name']?.toString() ?? '').replaceAll("'", "\\'");
    final country = a['country_code']?.toString() ?? '';

    if (icao.isEmpty || name.isEmpty || icao.length != 3) continue;
    if (seen.contains(icao)) continue; // Skip duplicates
    seen.add(icao);

    buf.writeln("  '$icao': AirlineInfo(icao: '$icao', iata: '$iata', name: '$name', country: '$country'),");
    count++;
  }

  buf.writeln('};');

  final outFile = File('lib/core/constants/airline_database.dart');
  await outFile.writeAsString(buf.toString());
  _log('Generated airline_database.dart with $count airlines');
}

Future<void> generateAirports() async {
  final file = File('proxy/cache/airports_raw.json');
  if (!await file.exists()) {
    _logError('airports_raw.json not found');
    return;
  }

  final data = jsonDecode(await file.readAsString());
  final airports = data['response'] as List;

  // Filter to airports with valid ICAO/IATA codes and coordinates
  final valid = airports.where((a) {
    final icao = a['icao_code']?.toString() ?? '';
    final lat = a['lat'];
    final lng = a['lng'];
    return icao.length == 4 && lat != null && lng != null;
  }).toList();

  final buf = StringBuffer();
  buf.writeln('/// Auto-generated airport database from Airlabs API.');
  buf.writeln('/// ${valid.length} airports total.');
  buf.writeln('/// Generated: ${DateTime.now().toIso8601String()}');
  buf.writeln();
  buf.writeln('class AirportEntry {');
  buf.writeln('  final String icao, iata, name, city, country;');
  buf.writeln('  final double lat, lon;');
  buf.writeln('  const AirportEntry(this.icao, this.iata, this.name, this.city, this.country, this.lat, this.lon);');
  buf.writeln('}');
  buf.writeln();
  buf.writeln('/// Lookup by ICAO code');
  buf.writeln('AirportEntry? lookupAirport(String icao) => airportFullDatabase[icao.toUpperCase()];');
  buf.writeln();
  buf.writeln('/// Lookup by IATA code');
  buf.writeln('AirportEntry? lookupAirportByIata(String iata) {');
  buf.writeln('  final code = iata.toUpperCase();');
  buf.writeln('  return airportFullDatabase.values.where((a) => a.iata == code).firstOrNull;');
  buf.writeln('}');
  buf.writeln();
  buf.writeln('/// Get city name for an IATA code');
  buf.writeln('String airportCity(String? iata) {');
  buf.writeln("  if (iata == null || iata.isEmpty) return '';");
  buf.writeln('  final apt = lookupAirportByIata(iata);');
  buf.writeln("  return apt?.city ?? '';");
  buf.writeln('}');
  buf.writeln();
  buf.writeln('/// Get country code for an IATA code');
  buf.writeln('String airportCountry(String? iata) {');
  buf.writeln("  if (iata == null || iata.isEmpty) return '';");
  buf.writeln('  final apt = lookupAirportByIata(iata);');
  buf.writeln("  return apt?.country ?? '';");
  buf.writeln('}');
  buf.writeln();
  buf.writeln('const Map<String, AirportEntry> airportFullDatabase = {');

  int count = 0;
  final seenApt = <String>{};
  for (final a in valid) {
    final icao = a['icao_code'].toString();
    if (seenApt.contains(icao)) continue;
    seenApt.add(icao);
    final iata = a['iata_code']?.toString() ?? '';
    final name = (a['name']?.toString() ?? '').replaceAll("'", "\\'");
    // Extract city name — prefer simple, short city names
    var city = (a['city']?.toString() ?? '').replaceAll("'", "\\'");
    if (city.isEmpty) {
      // Derive from airport name
      city = name
          .replaceAll(RegExp(r'\s*(International|Airport|Intl|Regional|Municipal|Metropolitan|Field|Air Base|AFB|Airbase|Aerodrome|Aeroport|Flughafen|Aeroporto|Aeropuerto|Lufthavn|Havaalani|Luchthaven|Flygplats|Lentoasema)\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*\(.*\)\s*'), '')
          .replaceAll(RegExp(r'\s*-\s*$'), '')
          .trim();
      if (city.contains(' - ')) city = city.split(' - ').first.trim();
      if (city.contains('/')) city = city.split('/').first.trim();
    }
    // Override with known city names for airports named after persons
    city = _knownCities[iata] ?? city;
    // Shorten if still too long
    if (city.length > 15) city = city.split(' ').first;
    if (city.endsWith('-')) city = city.substring(0, city.length - 1);
    final country = a['country_code']?.toString() ?? '';
    final lat = (a['lat'] as num).toDouble();
    final lng = (a['lng'] as num).toDouble();

    buf.writeln("  '$icao': AirportEntry('$icao', '$iata', '$name', '$city', '$country', $lat, $lng),");
    count++;
  }

  buf.writeln('};');

  final outFile = File('lib/core/constants/airport_full_database.dart');
  await outFile.writeAsString(buf.toString());
  _log('Generated airport_full_database.dart with $count airports');
}
