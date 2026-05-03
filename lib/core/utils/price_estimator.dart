import 'dart:math' as math;

/// Estimates flight prices based on route distance, class, and season.
/// This is an approximation — not real pricing data.
/// For actual prices, integrate with Skyscanner/Kiwi/Amadeus API.
class PriceEstimator {
  /// Estimate one-way price in EUR based on distance
  static PriceEstimate estimate({
    required double distanceKm,
    String? airlineType, // 'lowcost', 'standard', 'premium'
    bool isReturn = false,
  }) {
    // Base price per km (varies by airline type)
    final perKm = switch (airlineType) {
      'lowcost' => 0.04,
      'premium' => 0.12,
      _ => 0.07, // standard
    };

    // Distance-based pricing with diminishing returns
    final baseCost = distanceKm < 500
        ? distanceKm *
              perKm *
              1.5 // Short-haul premium
        : distanceKm < 2000
        ? 500 * perKm * 1.5 + (distanceKm - 500) * perKm
        : 500 * perKm * 1.5 + 1500 * perKm + (distanceKm - 2000) * perKm * 0.7;

    // Minimum price
    final economy = (baseCost + 30).clamp(35.0, 2000.0);
    final business = economy * 3.2;
    final first = economy * 6.5;

    final multiplier = isReturn ? 1.8 : 1.0; // Return is ~10% cheaper per leg

    return PriceEstimate(
      economy: (economy * multiplier).round(),
      business: (business * multiplier).round(),
      first: (first * multiplier).round(),
      distanceKm: distanceKm.round(),
    );
  }

  /// Calculate great-circle distance between two points
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

class PriceEstimate {
  final int economy;
  final int business;
  final int first;
  final int distanceKm;

  PriceEstimate({
    required this.economy,
    required this.business,
    required this.first,
    required this.distanceKm,
  });

  String get economyText => '~€$economy';
  String get businessText => '~€$business';
  String get firstText => '~€$first';
}
