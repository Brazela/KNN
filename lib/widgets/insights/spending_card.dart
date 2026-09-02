import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Summary card showing this month's total transport spend, split by
/// transit vs driving.
class SpendingCard extends StatelessWidget {
  /// Creates a [SpendingCard].
  const SpendingCard({
    required this.totalSpentRM,
    required this.transitSpentRM,
    required this.drivingSpentRM,
    super.key,
  });

  /// Total spent this month (MYR), across both modes.
  final double totalSpentRM;

  /// Portion spent on transit (MYR).
  final double transitSpentRM;

  /// Portion spent on driving (MYR).
  final double drivingSpentRM;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "THIS MONTH'S SPENDING",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(totalSpentRM),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ModeSpend(
                  icon: Icons.directions_transit_rounded,
                  label: 'Transit',
                  amountRM: transitSpentRM,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModeSpend(
                  icon: Icons.directions_car_rounded,
                  label: 'Driving',
                  amountRM: drivingSpentRM,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One mode's spend, shown side by side with the other mode.
class _ModeSpend extends StatelessWidget {
  const _ModeSpend({
    required this.icon,
    required this.label,
    required this.amountRM,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double amountRM;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatCurrency(amountRM),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
