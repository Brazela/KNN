import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../utils/constants.dart';

/// Line chart comparing transit vs driving cost over time for a saved
/// route.
///
/// Transit is drawn flat-ish (fares rarely change week to week) while
/// driving fluctuates (fuel prices do) — this is a deliberate reflection
/// of real Malaysian fuel/fare behaviour, not just decoration.
class CostTrendChart extends StatelessWidget {
  /// Creates a [CostTrendChart].
  const CostTrendChart({required this.points, super.key});

  /// Points to plot, in chronological order (oldest first).
  final List<CostTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final maxCost = points
        .expand((p) => [p.transitCost, p.drivingCost])
        .reduce((a, b) => a > b ? a : b);
    final chartMaxY = (maxCost * 1.25).ceilToDouble();
    final gridInterval = chartMaxY / 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
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
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Text(
              'Cost Trend',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 16),
            child: Row(
              children: const [
                _LegendDot(color: AppColors.primary, label: 'Driving'),
                SizedBox(width: 16),
                _LegendDot(color: AppColors.success, label: 'Transit'),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: 0,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: gridInterval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: gridInterval,
                      getTitlesWidget: (value, meta) => Text(
                        'RM${value.toInt()}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final label = index == points.length - 1
                            ? 'Now'
                            : '${points.length - 1 - index}w ago';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _line(
                    points.map((p) => p.drivingCost).toList(),
                    AppColors.primary,
                  ),
                  _line(
                    points.map((p) => p.transitCost).toList(),
                    AppColors.success,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _line(List<double> values, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < values.length; i++)
          FlSpot(i.toDouble(), values[i]),
      ],
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }
}

/// Small coloured-dot + label used in the chart legend.
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
