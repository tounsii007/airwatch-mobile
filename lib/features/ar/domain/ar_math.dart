import 'dart:math' as math;

/// Pure math for the AR-spotting view. No platform deps, easy to unit
/// test. Mirrors the web frontend's `arMath.ts` so a shared spec test
/// could compare both implementations bit-for-bit.
///
/// <p>Coordinate conventions:
/// <ul>
///   <li>Heading / bearing: degrees clockwise from true north (0–360).</li>
///   <li>Pitch: degrees above horizon (0 = horizon, +90 = zenith, −90 = ground).</li>
///   <li>Elevation angle: degrees from observer up to target.</li>
/// </ul>
const double _deg = math.pi / 180;

double _toRad(double deg) => deg * _deg;
double _toDeg(double rad) => rad / _deg;

/// Normalise an angle in degrees to [0, 360).
double normalizeDeg(double deg) {
  final m = deg % 360;
  return m < 0 ? m + 360 : m;
}

/// Shortest signed difference from `a` to `b` in (-180, 180].
///
/// <p>`shortestAngleDiff(350, 10) == 20` (going forward 20° crosses N).
/// Used by the compass HUD to decide which side ticks scroll off.
double shortestAngleDiff(double a, double b) {
  final diff = ((b - a + 540) % 360) - 180;
  return diff;
}

/// Initial great-circle bearing from `(lat1, lon1)` to `(lat2, lon2)`,
/// in degrees [0, 360). Same haversine-style spherical law as the web.
double bearingDeg(double lat1, double lon1, double lat2, double lon2) {
  final phi1 = _toRad(lat1);
  final phi2 = _toRad(lat2);
  final lambda = _toRad(lon2 - lon1);
  final y = math.sin(lambda) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(lambda);
  return normalizeDeg(_toDeg(math.atan2(y, x)));
}

/// Elevation angle (deg) looking from observer to a target at
/// `altMeters` above the observer, at `groundDistanceKm` ground
/// distance. Ignores Earth curvature (fine below ~100 km).
double elevationAngleDeg(double altMeters, double groundDistanceKm) {
  if (groundDistanceKm <= 0) return 90;
  final altKm = altMeters / 1000;
  return _toDeg(math.atan2(altKm, groundDistanceKm));
}

/// Project an aircraft's bearing + elevation into a normalised
/// `(x, y)` screen coordinate where:
/// <ul>
///   <li>`x = 0.5` is dead-centre, the axis the camera is pointing
///       along (= compass heading).</li>
///   <li>`y = 0.5` is the horizon line (= camera pitch).</li>
/// </ul>
///
/// <p>Returns `null` when the target is outside the camera's
/// horizontal field of view OR more than ±vfov/2 above/below the
/// horizon — i.e. when the AR overlay shouldn't render the marker.
({double x, double y})? projectToScreen({
  required double aircraftBearingDeg,
  required double aircraftElevationDeg,
  required double cameraHeadingDeg,
  required double cameraPitchDeg,
  required double horizontalFovDeg,
  required double verticalFovDeg,
}) {
  final dx = shortestAngleDiff(cameraHeadingDeg, aircraftBearingDeg);
  if (dx.abs() > horizontalFovDeg / 2) return null;

  final dy = aircraftElevationDeg - cameraPitchDeg;
  if (dy.abs() > verticalFovDeg / 2) return null;

  // Linear projection — accurate enough for FOVs ≤ 90°. Past that the
  // spherical projection diverges and you'd want a proper pinhole
  // model. Phone cameras top out around 78° H-FOV, so linear is fine.
  final x = 0.5 + dx / horizontalFovDeg;
  final y = 0.5 - dy / verticalFovDeg;
  return (x: x, y: y);
}
