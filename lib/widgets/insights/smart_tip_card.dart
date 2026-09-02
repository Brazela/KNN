import 'package:flutter/material.dart';

import '../../utils/constants.dart';

/// A single contextual tip row on the Insights Dashboard.
class SmartTipCard extends StatelessWidget {
  /// Creates a [SmartTipCard].
  const SmartTipCard({required this.icon, required this.text, super.key});

  /// Icon shown at the start of the row.
  final IconData icon;

  /// Tip body text.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
