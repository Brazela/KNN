import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../utils/constants.dart';

class FuelPriceHistoryPage extends StatefulWidget {
  const FuelPriceHistoryPage({super.key});

  @override
  State<FuelPriceHistoryPage> createState() => _FuelPriceHistoryPageState();
}

class _FuelPriceHistoryPageState extends State<FuelPriceHistoryPage> {
  List<FuelPrice> _history = [];
  bool _loading = true;
  String? _error;
  bool _showAllHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchHistory());
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = context.read<FuelPriceService>();
      final history = await service.getFuelPriceHistory();

      if (mounted) {
        setState(() {
          _history = history;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Price History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _fetchHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Could not load fuel price data',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return const Center(child: Text('No fuel price data available.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPriceTrendsSection(),
            const SizedBox(height: 20),
            _buildCurrentPricesSection(),
            const SizedBox(height: 20),
            _buildInsightsSection(),
            const SizedBox(height: 20),
            _buildPriceHistoryTable(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTrendsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Price Trends',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: _history.length < 2
              ? const Center(
                  child: Text(
                    'Not enough data for chart',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : LineChart(_buildChartData()),
        ),
      ],
    );
  }

  LineChartData _buildChartData() {
    // Use the most recent 20 records.
    final data = _history.take(20).toList().reversed.toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 0.5,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.border,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (value, meta) => Text(
              'RM${value.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 4,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
              final date = DateTime.tryParse(data[idx].date);
              if (date == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${date.day}/${date.month}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              );
            },
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
        ),
      ),
      lineBarsData: [
        _buildLineSeries(data, 'ron95', const Color(0xFFD97706)),   // amber
        _buildLineSeries(data, 'ron97', const Color(0xFF059669)),   // green
        _buildLineSeries(data, 'diesel', const Color(0xFF1D4ED8)),  // blue
      ],
      minY: _computeMinPrice() - 0.3,
      maxY: _computeMaxPrice() + 0.3,
    );
  }

  LineChartBarData _buildLineSeries(
    List<FuelPrice> data,
    String field,
    Color color,
  ) {
    return LineChartBarData(
      spots: data.asMap().entries.map((entry) {
        final value = switch (field) {
          'ron95' => entry.value.ron95,
          'ron97' => entry.value.ron97,
          'diesel' => entry.value.diesel,
          _ => 0.0,
        };
        return FlSpot(entry.key.toDouble(), value);
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }

  double _computeMinPrice() {
    double min = double.infinity;
    for (final p in _history) {
      if (p.ron95 < min) min = p.ron95;
      if (p.ron97 < min) min = p.ron97;
      if (p.diesel < min) min = p.diesel;
    }
    return min == double.infinity ? 2.0 : min;
  }

  double _computeMaxPrice() {
    double max = 0;
    for (final p in _history) {
      if (p.ron95 > max) max = p.ron95;
      if (p.ron97 > max) max = p.ron97;
      if (p.diesel > max) max = p.diesel;
    }
    return max == 0 ? 5.0 : max;
  }

  double? _weeklyChange(String field) {
    if (_history.length < 2) return null;
    final current = _getPrice(_history[0], field);
    final previous = _getPrice(_history[1], field);
    if (current == null || previous == null) return null;
    return current - previous;
  }

  double? _getPrice(FuelPrice p, String field) {
    return switch (field) {
      'ron95' => p.ron95,
      'ron97' => p.ron97,
      'diesel' => p.diesel,
      'dieselEastMsia' => p.dieselEastMsia,
      _ => null,
    };
  }

  Widget _buildCurrentPricesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⛽ Current Prices',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildPriceRow('RON 95', _history[0].ron95, _weeklyChange('ron95'), const Color(0xFFD97706)),
              const SizedBox(height: 12),
              _buildPriceRow('RON 97', _history[0].ron97, _weeklyChange('ron97'), const Color(0xFF059669)),
              const SizedBox(height: 12),
              _buildPriceRow('Diesel (Peninsular)', _history[0].diesel, _weeklyChange('diesel'), const Color(0xFF1D4ED8)),
              const SizedBox(height: 12),
              _buildPriceRow('Diesel (East MSIA)', _history[0].dieselEastMsia ?? double.nan, _weeklyChange('dieselEastMsia'), const Color(0xFF7C3AED)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double price, double? change, Color accent) {
    final priceText = price.isNaN ? 'N/A' : 'RM ${price.toStringAsFixed(2)}';
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (change != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _ChangeIndicator(change: change),
          ),
        Text(
          priceText,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceHistoryTable() {
    final limit = _showAllHistory ? _history.length : 5;
    final rows = _history.take(limit).toList().reversed.toList();
    final totalCount = _history.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📅 Price History',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFFF9FAFB),
              ),
              columnSpacing: 20,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 48,
              columns: const [
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataColumn(label: Text('RON95', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), numeric: true),
                DataColumn(label: Text('RON97', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), numeric: true),
                DataColumn(label: Text('Diesel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), numeric: true),
                DataColumn(label: Text('Change', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), numeric: true),
              ],
              rows: rows.map((p) {
                final change = _computeTableChange(p);
                return DataRow(cells: [
                  DataCell(Text(_formatShortDate(p.date), style: const TextStyle(fontSize: 12))),
                  DataCell(Text(p.ron95.toStringAsFixed(2), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                  DataCell(Text(p.ron97.toStringAsFixed(2), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                  DataCell(Text(p.diesel.toStringAsFixed(2), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                  DataCell(Text(
                    change != null ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}' : '-',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: change == null
                          ? AppColors.textMuted
                          : change > 0.005
                              ? const Color(0xFFDC2626)
                              : change < -0.005
                                  ? const Color(0xFF059669)
                                  : AppColors.textMuted,
                    ),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
        if (totalCount > 5)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _showAllHistory = !_showAllHistory);
                },
                icon: Icon(
                  _showAllHistory
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                ),
                label: Text(
                  _showAllHistory
                      ? 'Show less'
                      : 'Show all $totalCount records',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
      ],
    );
  }

  double? _computeTableChange(FuelPrice p) {
    final idx = _history.indexWhere((e) => e.date == p.date);
    if (idx < 0 || idx + 1 >= _history.length) return null;
    final next = _history[idx + 1];
    return p.ron95 - next.ron95;
  }

  String _formatShortDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _buildInsightText() {
    if (_history.length < 2) return 'Not enough data for insights.';
    final ron95Change = _weeklyChange('ron95');
    final ron97Change = _weeklyChange('ron97');
    final dieselChange = _weeklyChange('diesel');

    final String directionMsg;
    if ((ron95Change ?? 0) < -0.005 &&
        (ron97Change ?? 0) < -0.005 &&
        (dieselChange ?? 0) < -0.005) {
      directionMsg = 'RON95, RON97 & Diesel all dropped this week. Great time to fill up!';
    } else if ((ron95Change ?? 0) < -0.005) {
      final sen = ((-ron95Change!) * 100).round();
      directionMsg = 'RON95 dropped $sen sen this week.';
    } else if ((ron97Change ?? 0) < -0.005) {
      final sen = ((-ron97Change!) * 100).round();
      directionMsg = 'RON97 dropped $sen sen this week.';
    } else if ((dieselChange ?? 0) < -0.005) {
      final sen = ((-dieselChange!) * 100).round();
      directionMsg = 'Diesel dropped $sen sen this week.';
    } else if ((ron95Change ?? 0) > 0.005 ||
        (ron97Change ?? 0) > 0.005 ||
        (dieselChange ?? 0) > 0.005) {
      final changed = <String>[];
      for (final entry in [
        ('RON95', ron95Change),
        ('RON97', ron97Change),
        ('Diesel', dieselChange),
      ]) {
        if ((entry.$2 ?? 0) > 0.005) {
          changed.add('${entry.$1} rose ${(entry.$2! * 100).round()} sen');
        }
      }
      directionMsg = '${changed.join(', ')} this week.';
    } else {
      directionMsg = 'Prices unchanged this week.';
    }

    final weekday = DateTime.now().weekday;
    final String fillUpMsg;
    if (weekday == DateTime.monday || weekday == DateTime.tuesday) {
      fillUpMsg = 'Fill up before midnight tonight!';
    } else if (weekday == DateTime.wednesday) {
      fillUpMsg = 'Prices updated today.';
    } else {
      fillUpMsg = 'Fill up before next Wednesday.';
    }

    return '$directionMsg\n$fillUpMsg';
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💡 Insights',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _buildInsightText(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF065F46),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChangeIndicator extends StatelessWidget {
  const _ChangeIndicator({required this.change});

  final double change;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final String text;

    if (change > 0.005) {
      icon = Icons.arrow_upward_rounded;
      color = const Color(0xFFDC2626); // red
      text = '+RM ${change.toStringAsFixed(2)}';
    } else if (change < -0.005) {
      icon = Icons.arrow_downward_rounded;
      color = const Color(0xFF059669); // green
      text = '-RM ${(-change).toStringAsFixed(2)}';
    } else {
      icon = Icons.remove_rounded;
      color = AppColors.textMuted;
      text = 'RM 0.00';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
