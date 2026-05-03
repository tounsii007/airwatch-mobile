/// Unit conversion constants used throughout the app.
///
/// <p>Length conversions use the SI-defined exact relation 1 ft =
/// 0.3048 m. The earlier `3.28084` factor is short by ~3 ppm which
/// surfaces as off-by-one-foot errors at altitudes that are an exact
/// metric round number (e.g. 12 192 m, the metric equivalent of
/// FL400). Using the reciprocal of the exact 0.3048 keeps round-trips
/// (`m → ft → m`) bit-exact for canonical altitudes.
class ConversionConstants {
  // Length
  /// 1 m in feet. Exactly `1 / 0.3048` — the SI-defined reciprocal of
  /// the international foot. Equal to 3.2808398950131234… to within
  /// double precision.
  static const double metersToFeet = 1 / 0.3048;

  /// 1 ft in meters. Exact by definition.
  static const double feetToMeters = 0.3048;

  // Speed
  /// 1 m/s in knots. Exactly `3600 / 1852` since one nautical mile is
  /// 1 852 m by international agreement.
  static const double msToKnots = 3600.0 / 1852.0;
  static const double msToKmh = 3.6;

  /// 1 m/s in miles per hour. `3600 / 1609.344` — international mile.
  static const double msToMph = 3600.0 / 1609.344;

  // Vertical rate
  /// 1 m/s in feet per minute. `60 * (1 / 0.3048)` — derived from the
  /// length constant so all altitude units are mutually consistent.
  static const double msToFtPerMin = 60.0 / 0.3048;
  static const double msToMPerMin = 60.0;
}
