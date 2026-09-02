import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// A single bookmarked route row on the Favorites page.
///
/// Matches the Favorites page widget list exactly: Origin→Destination +
/// Mode + Savings + Plan button. Cost/time aren't shown here — that level
/// of detail lives on the Comparison page, which "Plan Route" opens.
///
/// Savings is formatted with the existing `formatCurrency` helper from
/// `utils/helpers.dart` rather than ad-hoc string interpolation, so a route
/// saved here reads identically to the same currency figures shown
/// elsewhere in the app.
class SavedRouteCard extends StatelessWidget {
  /// Creates a [SavedRouteCard].
  const SavedRouteCard({
    required this.route,
    required this.onPlanRoute,
    this.onTap,
    super.key,
  });

  /// The saved route this card displays.
  final SavedRoute route;

  /// Called when the user taps "Plan Route" (plan a trip on this route
  /// *now* — sets [TripProvider] and opens the live Comparison page).
  final VoidCallback onPlanRoute;

  /// Called when the user taps the card body (view saved-route detail —
  /// trend chart and savings history — separate from planning a trip now).
  final VoidCallback? onTap;

  bool get _isTransit => route.mode == TravelMode.transit;

  @override
  Widget build(BuildContext context) {
    final modeColor = _isTransit ? AppColors.success : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${route.origin.address ?? 'Origin'} → '
            '${route.destination.address ?? 'Destination'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _isTransit
                    ? Icons.directions_transit_rounded
                    : Icons.directions_car_rounded,
                size: 16,
                color: modeColor,
              ),
              const SizedBox(width: 6),
              Text(
                _isTransit ? 'Transit' : 'Driving',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: modeColor,
                ),
              ),
              Text(
                '  •  ',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Flexible(
                child: Text(
                  'Saves ${formatCurrency(route.savingsPerTripRM)}/trip',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPlanRoute,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Plan Route'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
