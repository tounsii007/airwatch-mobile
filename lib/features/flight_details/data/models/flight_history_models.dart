import 'package:airwatch_mobile/features/flight_details/data/models/flight_history_api_models.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';

class FlightHistoryProgress {
  final int step;
  final int total;
  final List<HistoryFlight> flights;

  const FlightHistoryProgress({
    required this.step,
    required this.total,
    required this.flights,
  });
}

class FlightHistoryResult {
  final List<HistoryFlight> flights;
  final AircraftMetadata? aircraftMeta;
  final AirlineInfo? airline;

  const FlightHistoryResult({
    required this.flights,
    this.aircraftMeta,
    this.airline,
  });
}

class HistoryFlight {
  final String icao24;
  final int firstSeen;
  final int lastSeen;
  final String? estDepartureAirport;
  final String? estArrivalAirport;
  final String? callsign;
  final int depHorizDistM;
  final int depVertDistM;
  final int arrHorizDistM;
  final int arrVertDistM;
  final int depCandidatesCount;
  final int arrCandidatesCount;
  final String? flightIcao;
  final String? flightIata;
  final String? depIata;
  final String? arrIata;
  final String? depTime;
  final String? arrTime;
  final String? depTerminal;
  final String? arrTerminal;
  final String? status;
  final int? depDelayMinutesApi;
  final int? arrDelayMinutesApi;
  final int? durationMinutes;
  int? expectedDurationMinutes;
  int? scheduledDepartureMinuteOfDay;
  String? inferredDepartureAirport;
  String? inferredArrivalAirport;

  HistoryFlight({
    required this.icao24,
    required this.firstSeen,
    required this.lastSeen,
    this.estDepartureAirport,
    this.estArrivalAirport,
    this.callsign,
    this.depHorizDistM = 0,
    this.depVertDistM = 0,
    this.arrHorizDistM = 0,
    this.arrVertDistM = 0,
    this.depCandidatesCount = 0,
    this.arrCandidatesCount = 0,
    this.flightIcao,
    this.flightIata,
    this.depIata,
    this.arrIata,
    this.depTime,
    this.arrTime,
    this.depTerminal,
    this.arrTerminal,
    this.status,
    this.depDelayMinutesApi,
    this.arrDelayMinutesApi,
    this.durationMinutes,
  });

  factory HistoryFlight.fromAirlabs(AirlabsFlightSnapshot flight) {
    final depTs = flight.departureTimestamp;
    final arrTs = flight.arrivalTimestamp;
    return HistoryFlight(
      icao24: flight.icao24,
      firstSeen: depTs,
      lastSeen: arrTs > 0 ? arrTs : depTs,
      estDepartureAirport: flight.departureIcao,
      estArrivalAirport: flight.arrivalIcao,
      callsign: flight.callsign,
      flightIcao: flight.flightIcao,
      flightIata: flight.flightIata,
      depIata: flight.depIata,
      arrIata: flight.arrIata,
      depTime: flight.depTime,
      arrTime: flight.arrTime,
      depTerminal: flight.depTerminal,
      arrTerminal: flight.arrTerminal,
      status: flight.status,
      depDelayMinutesApi: flight.depDelayMinutes,
      arrDelayMinutesApi: flight.arrDelayMinutes,
      durationMinutes: flight.durationMinutes,
    );
  }

  factory HistoryFlight.fromAirlabsRoute(AirlabsRouteSnapshot route) {
    return HistoryFlight(
      icao24: '',
      firstSeen: 0,
      lastSeen: 0,
      estDepartureAirport: route.departureIcao,
      estArrivalAirport: route.arrivalIcao,
      callsign: route.callsign,
      flightIcao: route.flightIcao,
      flightIata: route.flightIata,
      depIata: route.depIata,
      arrIata: route.arrIata,
      depTime: route.depTime,
      arrTime: route.arrTime,
      status: 'scheduled',
      durationMinutes: route.durationMinutes,
    );
  }

  factory HistoryFlight.fromJson(Map<String, dynamic> json) {
    final dep = json['estDepartureAirport'];
    final arr = json['estArrivalAirport'];

    return HistoryFlight(
      icao24: json['icao24']?.toString() ?? '',
      firstSeen: json['firstSeen'] as int? ?? 0,
      lastSeen: json['lastSeen'] as int? ?? 0,
      estDepartureAirport: dep is String ? dep : null,
      estArrivalAirport: arr is String ? arr : null,
      callsign: (json['callsign'] as String?)?.trim(),
      depHorizDistM: json['estDepartureAirportHorizDistance'] as int? ?? 0,
      depVertDistM: json['estDepartureAirportVertDistance'] as int? ?? 0,
      arrHorizDistM: json['estArrivalAirportHorizDistance'] as int? ?? 0,
      arrVertDistM: json['estArrivalAirportVertDistance'] as int? ?? 0,
      depCandidatesCount: json['departureAirportCandidatesCount'] as int? ?? 0,
      arrCandidatesCount: json['arrivalAirportCandidatesCount'] as int? ?? 0,
    );
  }

  DateTime get departureTime =>
      DateTime.fromMillisecondsSinceEpoch(firstSeen * 1000).toLocal();
  DateTime get arrivalTime =>
      DateTime.fromMillisecondsSinceEpoch(lastSeen * 1000).toLocal();
  Duration get duration => arrivalTime.difference(departureTime);

  String get durationText {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  DateTime? get scheduledDeparture {
    if (scheduledDepartureMinuteOfDay == null) return null;
    final d = departureTime;
    return DateTime(
      d.year,
      d.month,
      d.day,
      scheduledDepartureMinuteOfDay! ~/ 60,
      scheduledDepartureMinuteOfDay! % 60,
    );
  }

  DateTime? get scheduledArrival {
    final sd = scheduledDeparture;
    if (sd == null || expectedDurationMinutes == null) return null;
    return sd.add(Duration(minutes: expectedDurationMinutes!));
  }

  int? get departureDelayMinutes {
    final sd = scheduledDeparture;
    if (sd == null) return null;
    return departureTime.difference(sd).inMinutes;
  }

  int? get arrivalDelayMinutes {
    final sa = scheduledArrival;
    if (sa == null) return null;
    return arrivalTime.difference(sa).inMinutes;
  }

  bool get hasScheduleData => scheduledDepartureMinuteOfDay != null;
  bool get isDelayed => hasScheduleData && (departureDelayMinutes ?? 0) > 15;

  String get depDistanceText {
    if (depHorizDistM == 0) return '';
    if (depHorizDistM < 1000) return '${depHorizDistM}m from airport';
    return '${(depHorizDistM / 1000).toStringAsFixed(1)}km from airport';
  }

  String get arrDistanceText {
    if (arrHorizDistM == 0) return '';
    if (arrHorizDistM < 1000) return '${arrHorizDistM}m from airport';
    return '${(arrHorizDistM / 1000).toStringAsFixed(1)}km from airport';
  }

  bool get depIsReliable => depHorizDistM > 0 && depHorizDistM < 10000;
  bool get arrIsReliable => arrHorizDistM > 0 && arrHorizDistM < 10000;
  String? get effectiveDep => estDepartureAirport ?? inferredDepartureAirport;
  String? get effectiveArr => estArrivalAirport ?? inferredArrivalAirport;
  bool get hasDeparture => effectiveDep != null && effectiveDep!.isNotEmpty;
  bool get hasArrival => effectiveArr != null && effectiveArr!.isNotEmpty;
  bool get depIsInferred =>
      estDepartureAirport == null && inferredDepartureAirport != null;
  bool get arrIsInferred =>
      estArrivalAirport == null && inferredArrivalAirport != null;
}
