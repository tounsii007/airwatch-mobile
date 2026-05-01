import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:airwatch_mobile/core/constants/api_json_keys.dart';
import 'package:airwatch_mobile/core/constants/airport_database.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';
import 'package:airwatch_mobile/features/flight_details/data/models/flight_details_models.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

class FlightRefreshResult {
  final AircraftState? aircraft;
  final bool shouldReloadDetails;

  const FlightRefreshResult({this.aircraft, this.shouldReloadDetails = false});
}

class FlightDetailsService {
  final Dio _dio;
  final FlightInfoDatasource _datasource;

  FlightDetailsService({Dio? dio, FlightInfoDatasource? datasource})
      : _dio = dio ??
            AppHttpClient.create(
              connectTimeout: AppConfig.apiTimeout,
              receiveTimeout: AppConfig.longTimeout,
            ),
        _datasource = datasource ?? FlightInfoDatasource();

  AirlineInfo? resolveAirline(String? callsign) => _datasource.resolveAirline(callsign);

  Future<FlightDetailsData> load(AircraftState aircraft) async {
    final airline = resolveAirline(aircraft.callsign);
    if (kIsWeb) {
      return _loadViaLookup(aircraft, airline);
    }
    return _loadDirectly(aircraft, airline);
  }

  Future<FlightRefreshResult> refresh(
    AircraftState aircraft, {
    required bool hasRouteLoaded,
  }) async {
    final cs = aircraft.callsign?.trim() ?? '';
    final response = await _dio.get(AppConfig.flightUrl(flightIcao: cs));
    if (response.statusCode == 200 && response.data is Map) {
      final data = response.data as Map;
      final flight = data[ApiJsonKeys.response] as Map?;
      if (flight != null && flight.isNotEmpty) {
        final freshAircraft = aircraft.copyWith(
          latitude: (flight['lat'] as num?)?.toDouble(),
          longitude: (flight['lng'] as num?)?.toDouble(),
          baroAltitude: (flight['alt'] as num?)?.toDouble(),
          velocity: ((flight['speed'] as num?)?.toDouble() ?? 0) / 3.6,
          trueTrack: (flight['dir'] as num?)?.toDouble(),
          verticalRate: ((flight['v_speed'] as num?)?.toDouble() ?? 0) / 3.6,
        );
        return FlightRefreshResult(
          aircraft: freshAircraft,
          shouldReloadDetails: !hasRouteLoaded,
        );
      }
    }
    return FlightRefreshResult(shouldReloadDetails: !hasRouteLoaded);
  }

  Future<FlightDetailsData> _loadViaLookup(
    AircraftState aircraft,
    AirlineInfo? airline,
  ) async {
    final cs = aircraft.callsign?.trim() ?? '';
    final iata = airline?.iata ?? '';
    final response = await _dio.get(
      AppConfig.lookupUrl(aircraft.icao24, cs, iata),
    );
    if (response.statusCode != 200 || response.data is! Map) {
      return FlightDetailsData(airline: airline);
    }

    final data = response.data as Map;
    final meta = _parseAircraft(aircraft, data['aircraft']);
    final route =
        _parseFlightRoute(cs, data['flight']) ?? _parseRouteDb(cs, data['route_db']);
    final photoUrl = data['photo_url']?.toString();

    if (route != null) {
      await AirportDatabase.prefetch([
        if (route.departureAirport.isNotEmpty) route.departureAirport,
        if (route.arrivalAirport.isNotEmpty) route.arrivalAirport,
      ]);
    }

    return FlightDetailsData(
      airline: airline,
      route: route,
      metadata: meta,
      aircraftPhotoUrl: photoUrl != null ? AppConfig.imageProxyUrl(photoUrl) : null,
    );
  }

  Future<FlightDetailsData> _loadDirectly(
    AircraftState aircraft,
    AirlineInfo? airline,
  ) async {
    final results = await Future.wait([
      _datasource.getRouteByCallsign(
        aircraft.callsign?.trim() ?? '',
        icao24: aircraft.icao24,
      ),
      _datasource.getAircraftByIcao24(aircraft.icao24),
      FlightInfoDatasource.getAircraftPhotoUrl(aircraft.icao24),
    ]);

    final route = results[0] as FlightRouteInfo?;
    final meta = results[1] as AircraftMetadata?;
    final photo = results[2] as String?;

    if (route != null) {
      await AirportDatabase.prefetch([
        if (route.departureAirport.isNotEmpty) route.departureAirport,
        if (route.arrivalAirport.isNotEmpty) route.arrivalAirport,
      ]);
    }

    return FlightDetailsData(
      airline: airline,
      route: route,
      metadata: meta,
      aircraftPhotoUrl: photo,
    );
  }

  AircraftMetadata? _parseAircraft(AircraftState aircraft, dynamic raw) {
    if (raw is! Map) return null;
    return AircraftMetadata(
      icao24: aircraft.icao24,
      registration: raw['Registration']?.toString(),
      manufacturer: raw['Manufacturer']?.toString(),
      model: raw['Type']?.toString(),
      typecode: raw['ICAOTypeCode']?.toString(),
      operatorName: raw['RegisteredOwners']?.toString(),
      operatorIcao: raw['OperatorFlagCode']?.toString(),
    );
  }

  FlightRouteInfo? _parseFlightRoute(String callsign, dynamic raw) {
    if (raw is! Map || raw['dep_icao'] == null) return null;
    return FlightRouteInfo(
      callsign: callsign,
      departureAirport: raw['dep_icao']?.toString() ?? '',
      arrivalAirport: raw['arr_icao']?.toString() ?? '',
      operatorIata: raw['airline_iata']?.toString(),
      flightNumber: raw['flight_iata']?.toString(),
      source: 'airlabs',
      status: raw[ApiJsonKeys.status]?.toString(),
      depDelay: raw['dep_delayed'] as int?,
      arrDelay: raw['arr_delayed'] as int?,
      scheduledDep: raw['dep_time']?.toString(),
      scheduledArr: raw['arr_time']?.toString(),
      actualDep: raw['dep_estimated']?.toString() ?? raw['dep_actual']?.toString(),
      actualArr: raw['arr_estimated']?.toString() ?? raw['arr_actual']?.toString(),
      depTerminal: raw['dep_terminal']?.toString(),
      depGate: raw['dep_gate']?.toString(),
      arrTerminal: raw['arr_terminal']?.toString(),
      arrGate: raw['arr_gate']?.toString(),
      arrBaggage: raw['arr_baggage']?.toString(),
      duration: raw['duration'] as int?,
      aircraftModel: raw['model']?.toString(),
      aircraftManufacturer: raw['manufacturer']?.toString(),
      aircraftAge: raw['age'] as int?,
      aircraftBuilt: raw['built'] as int?,
      engineType: raw['engine']?.toString(),
    );
  }

  FlightRouteInfo? _parseRouteDb(String callsign, dynamic raw) {
    if (raw is! Map || raw['dep_icao'] == null) return null;
    return FlightRouteInfo(
      callsign: callsign,
      departureAirport: raw['dep_icao']?.toString() ?? '',
      arrivalAirport: raw['arr_icao']?.toString() ?? '',
      operatorIata: raw['airline_iata']?.toString(),
      flightNumber: raw['flight_iata']?.toString(),
      source: 'airlabs_routes',
      scheduledDep: raw['dep_time']?.toString(),
      scheduledArr: raw['arr_time']?.toString(),
      duration: raw['duration'] as int?,
    );
  }
}
