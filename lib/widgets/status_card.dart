import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Dark gradient card showing weather and transit status summary.
class StatusCard extends StatelessWidget {
  /// Creates a [StatusCard].
  const StatusCard({
    this.weatherText = 'Light rain expected',
    this.temperature = '26°C',
    this.nextTransitLabel = 'Next MRT',
    this.nextTransitValue = '8 min',
    this.destinationLabel = 'To KLCC',
    this.destinationValue = '3 stops',
    this.crowdingLabel = 'Crowding',
    this.crowdingValue = 'Moderate',
    super.key,
  });

  /// Weather summary text.
  final String weatherText;

  /// Temperature string.
  final String temperature;

  /// First status label.
  final String nextTransitLabel;

  /// First status value.
  final String nextTransitValue;

  /// Second status label.
  final String destinationLabel;

  /// Second status value.
  final String destinationValue;

  /// Third status label.
  final String crowdingLabel;

  /// Third status value.
  final String crowdingValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.darkSlate, AppColors.darkerSlate],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.wb_cloudy_rounded,
                size: 18,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  weatherText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              Text(
                temperature,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatusStat(label: nextTransitLabel, value: nextTransitValue),
              const SizedBox(width: 28),
              _StatusStat(label: destinationLabel, value: destinationValue),
              const SizedBox(width: 28),
              _StatusStat(label: crowdingLabel, value: crowdingValue),
            ],
          ),
        ],
      ),
    );
  }
}

/// Single label/value pair inside the status card.
class _StatusStat extends StatelessWidget {
  const _StatusStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.65),
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
