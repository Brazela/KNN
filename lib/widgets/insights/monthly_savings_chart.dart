import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../utils/constants.dart';

/// Bar chart showing accumulated monthly savings over the last several
/// months.
///
/// Uses the same `titlesData`/`gridData`/`borderData` structure as
/// [CostTrendChart] (already confirmed rendering correctly) — only the
/// chart body itself (`BarChartData`/`BarChartGroupData`/`BarChartRodData`)
/// is new, so this reuses API surface that's already proven to work rather
/// than introducing an entirely untested pattern.
class MonthlySavingsChart extends StatelessWidget {
  /// Creates a [MonthlySavingsChart].
  const MonthlySavingsChart({required this.points, super.key});

  /// Months to plot, in chronological order (oldest first).
  final List<MonthlySavings> points;

  static const _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final maxSaved = points.map((p) => p.savedRM).reduce(
          (a, b) => a > b ? a : b,
        );
    final chartMaxY = (maxSaved * 1.3).ceilToDouble();
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
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 16),
            child: Text(
              'Monthly Savings',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
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
                      reservedSize: 40,
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
                        final monthIndex = points[index].month.month - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _monthLabels[monthIndex],
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < points.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: points[i].savedRM,
                          color: AppColors.success,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
