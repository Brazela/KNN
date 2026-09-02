import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// "What if" retrospective comparison: what you actually spent this month
/// vs what you would have spent driving every trip instead.
///
/// This is the dashboard's version of the app's core pitch — the same
/// "wasting money without knowing" insight from the problem statement,
/// applied to the user's own numbers instead of a generic example.
class WhatIfCard extends StatelessWidget {
  /// Creates a [WhatIfCard].
  const WhatIfCard({
    required this.actualSpentRM,
    required this.alwaysDrivingSpentRM,
    super.key,
  });

  /// What was actually spent this month (mixing transit and driving).
  final double actualSpentRM;

  /// What would have been spent if every trip had been driven instead.
  final double alwaysDrivingSpentRM;

  double get _savedRM => alwaysDrivingSpentRM - actualSpentRM;

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
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'What if you always drove?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ScenarioColumn(
                  label: 'Actual',
                  amountRM: actualSpentRM,
                  color: AppColors.success,
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              Expanded(
                child: _ScenarioColumn(
                  label: 'Always driving',
                  amountRM: alwaysDrivingSpentRM,
                  color: AppColors.textSecondary,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.savingsBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'You saved ${formatCurrency(_savedRM)} by mixing in transit',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.savingsText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One side of the actual-vs-hypothetical comparison.
class _ScenarioColumn extends StatelessWidget {
  const _ScenarioColumn({
    required this.label,
    required this.amountRM,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final double amountRM;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          formatCurrency(amountRM),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
