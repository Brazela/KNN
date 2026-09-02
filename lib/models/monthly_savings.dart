/// A single month's accumulated savings, used by the Insights Dashboard's
/// monthly bar chart.
class MonthlySavings {
  /// Creates a [MonthlySavings] entry.
  const MonthlySavings({required this.month, required this.savedRM});

  /// The month this figure covers (only year/month are used for display).
  final DateTime month;

  /// Total saved (MYR) that month by choosing transit over driving.
  final double savedRM;
}
