import 'package:airwatch_mobile/core/utils/flight_code_formatter.dart';
import '../constants/conversion_constants.dart';

/// Share flight details as text.
/// On web, uses clipboard. On mobile, uses share sheet.
class ShareUtils {
  static String buildFlightShareText({
    required String callsign,
    String? airline,
    String? depIata,
    String? arrIata,
    String? aircraftType,
    String? status,
    double? altitude,
    double? speed,
  }) {
    final sb = StringBuffer();
    final displayCode = FlightCodeFormatter.displayFlightCode(
      callsign: callsign,
      fallback: callsign,
    );

    sb.writeln('Flight $displayCode');
    if (airline != null) sb.writeln('Airline: $airline');
    if (depIata != null && arrIata != null) {
      sb.writeln('Route: $depIata -> $arrIata');
    }
    if (aircraftType != null) sb.writeln('Aircraft: $aircraftType');
    if (status != null) sb.writeln('Status: $status');
    if (altitude != null) {
      sb.writeln(
        'Altitude: ${(altitude * ConversionConstants.metersToFeet).round()} ft',
      );
    }
    if (speed != null) {
      sb.writeln(
        'Speed: ${(speed * ConversionConstants.msToKnots).round()} kts',
      );
    }
    sb.writeln('\nTracked with AirWatch');
    return sb.toString();
  }
}
