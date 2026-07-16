import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/constants.dart';

/// A single step in a route's turn-by-turn or transit instructions.
///
/// Displays a step number badge, an icon, the description, duration,
/// and an optional realtime status indicator.
class RouteStepCard extends StatelessWidget {
  /// Creates a [RouteStepCard].
  const RouteStepCard({
    required this.stepNumber,
    required this.icon,
    required this.description,
    required this.duration,
    this.status,
    this.accentColor = AppColors.primary,
    super.key,
  });

  /// 1-based step number displayed in the circular badge.
  final int stepNumber;

  /// Icon representing the step type (walk, train, bus, etc.).
  final IconData icon;

  /// Human-readable step description.
  final String description;

  /// Duration text, e.g. "3 min" or "200m".
  final String duration;

  /// Optional realtime status for transit steps.
  final RealtimeStatus? status;

  /// Accent color for the step number badge.
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number badge — matches the numbered map marker style.
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Icon.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 12),

          // Description + status.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(height: 4),
                  _StatusDot(status: status!),
                ],
              ],
            ),
          ),

          // Duration.
          Text(
            duration,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small colored dot + label indicating realtime status.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final RealtimeStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      RealtimeStatus.onTime => (AppColors.success, 'On time'),
      RealtimeStatus.delayed => (const Color(0xFFF59E0B), 'Delayed'),
      RealtimeStatus.unknown => (AppColors.textMuted, 'No realtime data'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
