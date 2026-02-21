class PricingMetrics {
  final double msrp;
  final double marketAverage;
  final double fairRangeLow;
  final double fairRangeHigh;

  PricingMetrics({
    required this.msrp,
    required this.marketAverage,
    required this.fairRangeLow,
    required this.fairRangeHigh,
  });

  factory PricingMetrics.fromJson(Map<String, dynamic> json) {
    return PricingMetrics(
      msrp: (json['msrp'] as num?)?.toDouble() ?? 0.0,
      marketAverage: (json['market_average'] as num?)?.toDouble() ?? 0.0,
      fairRangeLow: (json['fair_range_low'] as num?)?.toDouble() ?? 0.0,
      fairRangeHigh: (json['fair_range_high'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class VehicleValuation {
  final Map<String, dynamic> vehicleIdentifiers;
  final PricingMetrics metrics;
  final Map<String, dynamic> metadata;

  VehicleValuation({
    required this.vehicleIdentifiers,
    required this.metrics,
    required this.metadata,
  });

  factory VehicleValuation.fromJson(Map<String, dynamic> json) {
    return VehicleValuation(
      vehicleIdentifiers:
          json['vehicle_identifiers'] as Map<String, dynamic>? ?? {},
      metrics: PricingMetrics.fromJson(json['pricing_metrics'] ?? {}),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}
