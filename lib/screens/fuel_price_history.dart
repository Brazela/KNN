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
            _buildPriceHistoryTable(),
            const SizedBox(height: 20),
            _buildInsightsSection(),
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
              if (_history[0].dieselEastMsia != null) ...[
                const SizedBox(height: 12),
                _buildPriceRow('Diesel (East MSIA)', _history[0].dieselEastMsia!, _weeklyChange('dieselEastMsia'), const Color(0xFF7C3AED)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double price, double? change, Color accent) {
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
          'RM ${price.toStringAsFixed(2)}',
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
    return const SizedBox.shrink(); // Task 8
  }

  Widget _buildInsightsSection() {
    return const SizedBox.shrink(); // Task 9
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
