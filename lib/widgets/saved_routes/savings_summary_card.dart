import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Compact stat card showing accumulated savings and trip count for a
/// saved route.
class SavingsSummaryCard extends StatelessWidget {
  /// Creates a [SavingsSummaryCard].
  const SavingsSummaryCard({
    required this.totalSavedRM,
    required this.tripCount,
    super.key,
  });

  /// Total money saved (MYR) on this route so far.
  final double totalSavedRM;

  /// Number of trips this total is based on.
  final int tripCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.savingsBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.savings_rounded,
            size: 30,
            color: AppColors.success,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Saved',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.savingsText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatCurrency(totalSavedRM),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.savingsText,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$tripCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.savingsText,
                ),
              ),
              const Text(
                'trips',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.savingsText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
