import 'package:flutter_test/flutter_test.dart';
import 'package:airwatch_mobile/core/utils/price_estimator.dart';

void main() {
  group('PriceEstimator', () {
    test('short-haul flight price', () {
      final est = PriceEstimator.estimate(distanceKm: 400);
      expect(est.economy, greaterThan(35));
      expect(est.economy, lessThan(150));
      expect(est.business, greaterThan(est.economy));
      expect(est.first, greaterThan(est.business));
    });

    test('long-haul flight price', () {
      final est = PriceEstimator.estimate(distanceKm: 8000);
      expect(est.economy, greaterThan(200));
      expect(est.economy, lessThan(1500));
    });

    test('lowcost airline is cheaper', () {
      final standard = PriceEstimator.estimate(distanceKm: 1000);
      final lowcost = PriceEstimator.estimate(
        distanceKm: 1000,
        airlineType: 'lowcost',
      );
      expect(lowcost.economy, lessThan(standard.economy));
    });

    test('premium airline is more expensive', () {
      final standard = PriceEstimator.estimate(distanceKm: 1000);
      final premium = PriceEstimator.estimate(
        distanceKm: 1000,
        airlineType: 'premium',
      );
      expect(premium.economy, greaterThan(standard.economy));
    });

    test('return is cheaper per leg than 2x one-way', () {
      final oneWay = PriceEstimator.estimate(distanceKm: 3000);
      final ret = PriceEstimator.estimate(distanceKm: 3000, isReturn: true);
      expect(ret.economy, lessThan(oneWay.economy * 2));
    });

    test('minimum price is 35 EUR', () {
      final est = PriceEstimator.estimate(distanceKm: 10);
      expect(est.economy, greaterThanOrEqualTo(35));
    });

    test('first class is ~6x economy', () {
      final est = PriceEstimator.estimate(distanceKm: 5000);
      final ratio = est.first / est.economy;
      expect(ratio, closeTo(6.5, 1));
    });

    test('distanceKm calculation Frankfurt-Paris', () {
      final dist = PriceEstimator.distanceKm(50.033, 8.571, 49.010, 2.548);
      expect(dist, closeTo(450, 20));
    });

    test('distanceKm same point is 0', () {
      final dist = PriceEstimator.distanceKm(50, 8, 50, 8);
      expect(dist, closeTo(0, 0.001));
    });
  });
}
