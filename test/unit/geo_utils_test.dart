import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:airwatch_mobile/core/utils/geo_utils.dart';

void main() {
  group('GeoUtils', () {
    test('distanceKm between Frankfurt and Paris', () {
      const fra = LatLng(50.033, 8.571);
      const cdg = LatLng(49.010, 2.548);
      final dist = GeoUtils.distanceKm(fra, cdg);
      expect(dist, closeTo(450, 20)); // ~450 km
    });

    test('distanceKm between same point is 0', () {
      const p = LatLng(50, 8);
      expect(GeoUtils.distanceKm(p, p), closeTo(0, 0.001));
    });

    test('distanceKm London to New York', () {
      const lhr = LatLng(51.470, -0.454);
      const jfk = LatLng(40.640, -73.779);
      final dist = GeoUtils.distanceKm(lhr, jfk);
      expect(dist, closeTo(5570, 50)); // ~5570 km
    });

    test('interpolate returns midpoint', () {
      const a = LatLng(0, 0);
      const b = LatLng(10, 10);
      final mid = GeoUtils.interpolate(a, b, 0.5);
      expect(mid.latitude, closeTo(5, 0.001));
      expect(mid.longitude, closeTo(5, 0.001));
    });

    test('interpolate at 0 returns start', () {
      const a = LatLng(10, 20);
      const b = LatLng(30, 40);
      final result = GeoUtils.interpolate(a, b, 0);
      expect(result.latitude, 10);
      expect(result.longitude, 20);
    });

    test('interpolate at 1 returns end', () {
      const a = LatLng(10, 20);
      const b = LatLng(30, 40);
      final result = GeoUtils.interpolate(a, b, 1);
      expect(result.latitude, 30);
      expect(result.longitude, 40);
    });

    test('bearing north is ~0', () {
      const a = LatLng(50, 8);
      const b = LatLng(51, 8);
      final bearing = GeoUtils.bearing(a, b);
      expect(bearing, closeTo(0, 2));
    });

    test('bearing east is ~90', () {
      const a = LatLng(50, 8);
      const b = LatLng(50, 9);
      final bearing = GeoUtils.bearing(a, b);
      expect(bearing, closeTo(90, 5));
    });

    test('isInBounds works correctly', () {
      const sw = LatLng(40, 0);
      const ne = LatLng(55, 15);
      expect(GeoUtils.isInBounds(const LatLng(50, 8), sw, ne), true);
      expect(GeoUtils.isInBounds(const LatLng(30, 8), sw, ne), false);
      expect(GeoUtils.isInBounds(const LatLng(50, 20), sw, ne), false);
    });
  });
}
