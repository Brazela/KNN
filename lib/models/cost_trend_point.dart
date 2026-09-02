/// A single point in a saved route's cost-over-time trend.
///
/// Kept separate from [SavedRoute] rather than adding a history list to it
/// — [SavedRoute] represents the route's current snapshot (used by the
/// Favorites list), while this is historical data specific to the detail
/// page's trend chart.
class CostTrendPoint {
  /// Creates a [CostTrendPoint].
  const CostTrendPoint({
    required this.date,
    required this.transitCost,
    required this.drivingCost,
  });

  /// When this cost snapshot was recorded.
  final DateTime date;

  /// Transit cost (MYR) at this point in time.
  final double transitCost;

  /// Driving cost (MYR) at this point in time.
  final double drivingCost;
}
