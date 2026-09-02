import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/widgets.dart';

/// Saved Route Comparison — detail view for a single saved route: a live
/// cost comparison, a cost-over-time trend chart, and an accumulated
/// savings summary.
///
/// Reached by tapping a [SavedRouteCard] on the Favorites page (not its
/// "Plan Route" button, which still goes straight to the live Comparison
/// page for planning a trip *now*). This page is for reviewing a route you
/// already travel regularly.
///
/// UI-mockup implementation: the trend points and trip count are derived
/// dummy data anchored to the real [route] passed in — see [_dummyTrend]
/// for how.
class SavedRouteComparisonPage extends StatelessWidget {
  /// Creates a [SavedRouteComparisonPage] for [route].
  const SavedRouteComparisonPage({required this.route, super.key});

  /// The saved route this page shows detail for.
  final SavedRoute route;

  bool get _isTransitRecommended => route.mode == TravelMode.transit;

  /// The alternative mode's cost, derived from [SavedRoute.savingsPerTripRM]
  /// — the alternative is always more expensive than the recommended mode
  /// by exactly the savings amount, regardless of which mode is
  /// recommended.
  double get _alternativeCost => route.cost + route.savingsPerTripRM;

  /// Generates a plausible cost history ending at the route's real current
  /// cost. Transit is held flat (fixed fares); driving fluctuates week to
  /// week (fuel prices do) around its current value.
  static List<CostTrendPoint> _dummyTrend(SavedRoute route) {
    final now = DateTime.now();
    final alternativeCost = route.cost + route.savingsPerTripRM;
    final transitCost =
        route.mode == TravelMode.transit ? route.cost : alternativeCost;
    final drivingBase =
        route.mode == TravelMode.driving ? route.cost : alternativeCost;
    const variations = [0.93, 1.02, 1.07, 0.97, 1.04, 1.0];

    return [
      for (var i = 0; i < variations.length; i++)
        CostTrendPoint(
          date: now.subtract(Duration(days: (variations.length - 1 - i) * 7)),
          transitCost: double.parse(transitCost.toStringAsFixed(2)),
          drivingCost: double.parse(
            (drivingBase * variations[i]).toStringAsFixed(2),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final trend = _dummyTrend(route);

    // Mockup assumption: saved routes are used roughly 3x/week; the trend
    // chart above covers 5 weeks, so 15 trips is used consistently as the
    // basis for the savings summary below.
    const estimatedTrips = 15;
    final totalSaved = route.savingsPerTripRM * estimatedTrips;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final hPad = isWide ? 40.0 : 20.0;
            const maxW = 480.0;

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      CostComparisonCard(
                        driveCost: formatCurrency(
                          _isTransitRecommended
                              ? _alternativeCost
                              : route.cost,
                        ),
                        transitCost: formatCurrency(
                          _isTransitRecommended
                              ? route.cost
                              : _alternativeCost,
                        ),
                        savingsText: 'Save '
                            '${formatCurrency(route.savingsPerTripRM)} by '
                            'taking '
                            '${_isTransitRecommended ? 'transit' : 'driving'}',
                      ),
                      const SizedBox(height: 16),
                      CostTrendChart(points: trend),
                      const SizedBox(height: 16),
                      SavingsSummaryCard(
                        totalSavedRM: totalSaved,
                        tripCount: estimatedTrips,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saved Route',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${route.origin.address ?? 'Origin'} → '
                '${route.destination.address ?? 'Destination'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
