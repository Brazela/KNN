import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Card previewing the cost comparison between driving and transit.
class CostComparisonCard extends StatelessWidget {
  /// Creates a [CostComparisonCard].
  const CostComparisonCard({
    this.driveCost = 'RM 18',
    this.transitCost = 'RM 3',
    this.savingsText = 'You save RM 15 by taking transit today',
    super.key,
  });

  /// Displayed driving cost.
  final String driveCost;

  /// Displayed transit cost.
  final String transitCost;

  /// Savings highlight text.
  final String savingsText;

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
          const Row(
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                'Cost comparison',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ModeCostTile(
                icon: Icons.directions_car_rounded,
                label: 'Drive',
                cost: driveCost,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _ModeCostTile(
                icon: Icons.directions_transit_rounded,
                label: 'Transit',
                cost: transitCost,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.savingsBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.savings_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  savingsText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.savingsText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Single mode cost tile inside the comparison card.
class _ModeCostTile extends StatelessWidget {
  const _ModeCostTile({
    required this.icon,
    required this.label,
    required this.cost,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String cost;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.8),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cost,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
