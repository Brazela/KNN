import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/address_utils.dart';
import '../utils/helpers.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    required this.trip,
    required this.onCompareAgain,
    super.key,
  });

  final Trip trip;
  final VoidCallback onCompareAgain;

  @override
  Widget build(BuildContext context) {
    final hasRecommendation = trip.recommendedMode != null && trip.recommendedMode != 'either';
    final followed = trip.followedRecommendation == 1;
    final recommendedTransit = trip.recommendedMode == 'transit';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header.
          Text(
            formatDateTime(trip.date),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'From: ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: shortAddress(trip.origin),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'To: ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: shortAddress(trip.destination),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Recommended badge.
          if (hasRecommendation)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (recommendedTransit ? AppColors.success : AppColors.primary)
                    .withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (recommendedTransit ? AppColors.success : AppColors.primary)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    recommendedTransit
                        ? Icons.directions_transit_rounded
                        : Icons.directions_car_rounded,
                    size: 16,
                    color: recommendedTransit ? AppColors.success : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Recommended: ${recommendedTransit ? "Transit" : "Driving"}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: recommendedTransit ? AppColors.success : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(Actual: ${trip.mode == TravelMode.transit ? "Transit" : "Driving"})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Transit vs Driving cost/time side by side.
          Row(
            children: [
              if (trip.transitCost != null) ...[
                _ModeMiniTile(
                  icon: Icons.directions_transit_rounded,
                  label: 'Transit',
                  cost: formatCurrency(trip.transitCost!),
                  time: formatDuration(trip.transitTime ?? 0),
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
              ],
              if (trip.drivingCost != null)
                _ModeMiniTile(
                  icon: Icons.directions_car_rounded,
                  label: 'Driving',
                  cost: formatCurrency(trip.drivingCost!),
                  time: formatDuration(trip.drivingTime ?? 0),
                  color: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Follow badge + savings/loss.
          if (hasRecommendation) ...[
            Row(
              children: [
                Icon(
                  followed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 18,
                  color: followed ? AppColors.success : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  followed
                      ? 'You followed the recommendation'
                      : "You didn't follow the recommendation",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: followed ? AppColors.savingsText : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (trip.savingsCost != null || trip.savingsTime != null) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (trip.savingsCost != null && trip.savingsCost! >= 0)
                      ? AppColors.savingsBackground
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      trip.savingsCost != null && trip.savingsCost! >= 0
                          ? Icons.savings_rounded
                          : Icons.trending_up_rounded,
                      size: 16,
                      color: trip.savingsCost != null && trip.savingsCost! >= 0
                          ? AppColors.success
                          : const Color(0xFF9A3412),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _savingsText(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: trip.savingsCost != null && trip.savingsCost! >= 0
                              ? AppColors.savingsText
                              : const Color(0xFF9A3412),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),

          // Compare Again button.
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onCompareAgain,
              icon: const Text('🔄', style: TextStyle(fontSize: 14)),
              label: const Text(
                'Compare Again',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _savingsText() {
    final parts = <String>[];
    if (trip.savingsCost != null) {
      if (trip.savingsCost! >= 0) {
        parts.add('Saved ${formatCurrency(trip.savingsCost!)}');
      } else {
        parts.add('Paid ${formatCurrency(trip.savingsCost!.abs())} more');
      }
    }
    if (trip.savingsTime != null) {
      if (trip.savingsTime! >= 0) {
        parts.add('Saved ${formatDuration(trip.savingsTime!)}');
      } else {
        parts.add('Lost ${formatDuration(trip.savingsTime!.abs())}');
      }
    }
    if (parts.isEmpty) return 'No savings data';
    return parts.join(', ');
  }
}

class _ModeMiniTile extends StatelessWidget {
  const _ModeMiniTile({
    required this.icon,
    required this.label,
    required this.cost,
    required this.time,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String cost;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    cost,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
