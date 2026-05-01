/// Centralized Airlabs API field names.
/// Prevents typos and enables bulk refactoring.
class ApiJsonKeys {
  const ApiJsonKeys._();

  // ═══ Response Envelope ═══
  static const String response = 'response';
  static const String status = 'status';

  // ═══ Flight Identification ═══
  static const String flightIcao = 'flight_icao';
  static const String flightIata = 'flight_iata';
  static const String flightNumber = 'flight_number';
  static const String airlineIcao = 'airline_icao';
  static const String airlineIata = 'airline_iata';

  // ═══ Departure ═══
  static const String depIcao = 'dep_icao';
  static const String depIata = 'dep_iata';
  static const String depTerminal = 'dep_terminal';
  static const String depGate = 'dep_gate';
  static const String depTime = 'dep_time';
  static const String depTimeUtc = 'dep_time_utc';
  static const String depEstimated = 'dep_estimated';
  static const String depActual = 'dep_actual';
  static const String depDelayed = 'dep_delayed';

  // ═══ Arrival ═══
  static const String arrIcao = 'arr_icao';
  static const String arrIata = 'arr_iata';
  static const String arrTerminal = 'arr_terminal';
  static const String arrGate = 'arr_gate';
  static const String arrBaggage = 'arr_baggage';
  static const String arrTime = 'arr_time';
  static const String arrTimeUtc = 'arr_time_utc';
  static const String arrEstimated = 'arr_estimated';
  static const String arrActual = 'arr_actual';
  static const String arrDelayed = 'arr_delayed';

  // ═══ Flight Status ═══
  static const String duration = 'duration';

  // ═══ Aircraft ═══
  static const String hex = 'hex';
  static const String regNumber = 'reg_number';
  static const String aircraftIcao = 'aircraft_icao';
  static const String model = 'model';
  static const String manufacturer = 'manufacturer';
  static const String type = 'type';
  static const String engine = 'engine';
  static const String engineCount = 'engine_count';
  static const String built = 'built';
  static const String age = 'age';
  static const String msn = 'msn';

  // ═══ Position ═══
  static const String lat = 'lat';
  static const String lng = 'lng';
  static const String alt = 'alt';
  static const String speed = 'speed';
  static const String dir = 'dir';
  static const String vSpeed = 'v_speed';
  static const String squawk = 'squawk';
  static const String flag = 'flag';
  static const String updated = 'updated';

  // ═══ Route lookup ═══
  static const String path = 'path';
}
