import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/constants.dart';

class RouteStepCard extends StatelessWidget {

  const RouteStepCard({
    required this.stepNumber,
    required this.icon,
    required this.description,
    required this.duration,
    this.status,
    this.accentColor = AppColors.primary,
    this.isActive = false,
    this.isCompleted = false,
    super.key,
  });

  final int stepNumber;

  final IconData icon;

  final String description;

  final String duration;

  final RealtimeStatus? status;

  final Color accentColor;

  final bool isActive;

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final descriptionColor = isCompleted
        ? AppColors.textMuted
        : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? accentColor.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isActive
            ? Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.2)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success : accentColor,
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
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    )
                  : Text(
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

          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isCompleted
                  ? AppColors.textMuted
                  : AppColors.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: descriptionColor,
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

          Text(
            duration,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isCompleted
                  ? AppColors.textMuted
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

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
