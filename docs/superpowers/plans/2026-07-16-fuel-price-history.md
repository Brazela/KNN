# Fuel Price History Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a full-screen Fuel Price History page with line chart, current prices, history table, and insights, plus a "Details" link on the homepage fuel widget.

**Architecture:** New `FuelPriceHistoryPage` screen fetches history from the existing data.gov.my JSON API via a new `FuelPriceService.getFuelPriceHistory()` method. Uses `fl_chart` for the line chart. Homepage `FuelPriceWidget` gains a "Details" text link navigating to the new route.

**Tech Stack:** Flutter, fl_chart, data.gov.my JSON API

## Global Constraints
- `fl_chart: ^0.69.0` added to pubspec.yaml
- Color mapping: RON95 = amber, RON97 = green, Diesel = blue
- All existing card styling (white bg, border radius 16, AppColors.border) preserved
- Follow barrel export pattern for all new files

---

### Task 1: Add fl_chart dependency & parameterize fuel price URL

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/utils/constants.dart`

**Interfaces:**
- Produces: `ApiUrls.fuelPriceLatestUrl` (getter, limit=1), `ApiUrls.fuelPriceHistoryUrl({int limit})` (method)

- [ ] **Step 1: Add fl_chart to pubspec.yaml**

Insert `fl_chart: ^0.69.0` after the existing `json_annotation` line:

```yaml
  json_annotation: ^4.9.0
  fl_chart: ^0.69.0
```

- [ ] **Step 2: Replace fuelPriceUrl with parameterized version in constants.dart**

Replace lines 29-34:

```dart
  /// data.gov.my fuel price catalogue endpoint.
  ///
  /// Sorts by date descending and filters for price levels (not weekly
  /// changes) so the first result is always the most recent price.
  static const String fuelPriceBaseUrl =
      'https://api.data.gov.my/data-catalogue?id=fuelprice&sort=-date&series_type=level';

  static String fuelPriceUrl({int limit = 1}) =>
      '$fuelPriceBaseUrl&limit=$limit';

  static String get fuelPriceLatestUrl => fuelPriceUrl();

  static String fuelPriceHistoryUrl({int limit = 50}) =>
      fuelPriceUrl(limit: limit);
```

- [ ] **Step 3: Run pub get**

```bash
cd /home/nwc/StudioProjects/KNN && flutter pub get
```

Expected: `Process exit code 0`, fl_chart resolved.

- [ ] **Step 4: Commit**

```bash
cd /home/nwc/StudioProjects/KNN && git add pubspec.yaml pubspec.lock lib/utils/constants.dart && git commit -m "chore: add fl_chart, parameterize fuel price URL"
```

---

### Task 2: Add getFuelPriceHistory to FuelPriceService

**Files:**
- Modify: `lib/services/fuel_price_service.dart`

**Interfaces:**
- Produces: `FuelPriceService.getFuelPriceHistory({int limit}) → Future<List<FuelPrice>>`
- Consumes: `ApiUrls.fuelPriceHistoryUrl()`, `FuelPrice.fromJson()`

- [ ] **Step 1: Add getFuelPriceHistory method to fuel_price_service.dart**

Insert after the existing `getFuelPrice()` method (before closing brace):

```dart
  /// Fetches the most recent [limit] fuel price level records.
  ///
  /// The API may intermix `series_type=level` and `series_type=change_weekly`
  /// records — this method filters to only level records.
  Future<List<FuelPrice>> getFuelPriceHistory({int limit = 50}) async {
    final response = await _client.get(
      Uri.parse(ApiUrls.fuelPriceHistoryUrl(limit: limit)),
    );

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to fetch fuel price history: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    final levelRecords = data
        .where((e) =>
            (e as Map<String, dynamic>)['series_type'] == 'level')
        .map((e) => FuelPrice.fromJson(e as Map<String, dynamic>))
        .toList();

    if (levelRecords.isEmpty) {
      throw Exception('No level-type fuel price records found');
    }

    return levelRecords;
  }
```

- [ ] **Step 2: Fix existing getFuelPrice to use fuelPriceLatestUrl**

Replace `ApiUrls.fuelPriceUrl` on line 23:

```dart
    final response = await _client.get(Uri.parse(ApiUrls.fuelPriceLatestUrl));
```

- [ ] **Step 3: Commit**

```bash
cd /home/nwc/StudioProjects/KNN && git add lib/services/fuel_price_service.dart && git commit -m "feat: add getFuelPriceHistory to FuelPriceService"
```

---

### Task 3: Add fuel price history route

**Files:**
- Modify: `lib/navigation/app_routes.dart`
- Modify: `lib/screens/screens.dart`

**Interfaces:**
- Produces: `AppRoutes.fuelPriceHistory = '/fuel-price-history'`

- [ ] **Step 1: Add route constant to app_routes.dart**

Insert after `profile` (line 42):

```dart
  /// Fuel price history route.
  static const String fuelPriceHistory = '/fuel-price-history';
```

- [ ] **Step 2: Add switch case in _buildPage**

Insert before `case tripHistory` (line 75):

```dart
      case fuelPriceHistory:
        return const FuelPriceHistoryPage();
```

- [ ] **Step 3: Add export to screens barrel**

Append to `lib/screens/screens.dart`:

```dart
export 'fuel_price_history.dart';
```

- [ ] **Step 4: Commit**

```bash
cd /home/nwc/StudioProjects/KNN && git add lib/navigation/app_routes.dart lib/screens/screens.dart && git commit -m "feat: add fuel price history route"
```

---

### Task 4: Add "Details" link to homepage fuel price widget

**Files:**
- Modify: `lib/widgets/fuel_price_widget.dart`

**Interfaces:**
- Consumes: `AppRoutes.fuelPriceHistory`

- [ ] **Step 1: Add navigation import at top of fuel_price_widget.dart**

Insert after the existing imports:

```dart
import '../navigation/navigation.dart';
```

- [ ] **Step 2: Insert "Details →" TextButton in the header row**

In `_buildContent`, inside the header `Row` (after the `Expanded(child: Text('Fuel Prices'))` block, before the date badge `Container`), insert:

```dart
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.fuelPriceHistory,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Details →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
```

- [ ] **Step 3: Commit**

```bash
cd /home/nwc/StudioProjects/KNN && git add lib/widgets/fuel_price_widget.dart && git commit -m "feat: add Details link to fuel price widget header"
```

---

### Task 5: Create FuelPriceHistoryPage skeleton with fetch

**Files:**
- Create: `lib/screens/fuel_price_history.dart`

**Interfaces:**
- Consumes: `FuelPriceService.getFuelPriceHistory()`, `FuelPrice` model
- Produces: `FuelPriceHistoryPage` widget

- [ ] **Step 1: Create fuel_price_history.dart with loading/error/data skeleton**

```dart
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
    return const SizedBox.shrink(); // Task 6
  }

  Widget _buildCurrentPricesSection() {
    return const SizedBox.shrink(); // Task 7
  }

  Widget _buildPriceHistoryTable() {
    return const SizedBox.shrink(); // Task 8
  }

  Widget _buildInsightsSection() {
    return const SizedBox.shrink(); // Task 9
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd /home/nwc/StudioProjects/KNN && git add lib/screens/fuel_price_history.dart && git commit -m "feat: add FuelPriceHistoryPage skeleton"
```

---

### Task 6: Build Price Trends line chart

**Files:**
- Modify: `lib/screens/fuel_price_history.dart`

- [ ] **Step 1: Add fl_chart import**

```dart
import 'package:fl_chart/fl_chart.dart';
```

- [ ] **Step 2: Replace _buildPriceTrendsSection stub**

```dart
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
```

- [ ] **Step 3: Commit**

```bash
cd /home/nwc/StudioProjects/KNN && git add lib/screens/fuel_price_history.dart && git commit -m "feat: add price trends line chart"
```

---

### Task 7: Build Current Prices section with change indicators

**Files:**
- Modify: `lib/screens/fuel_price_history.dart`

- [ ] **Step 1: Add helper method for computing weekly change**

Add to `_FuelPriceHistoryPageState`:

```dart
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
      _ => null,
    };
  }
```

- [ ] **Step 2: Replace _buildCurrentPricesSection stub**

```dart
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
```

- [ ] **Step 3: Add _ChangeIndicator widget at file bottom**

```dart
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
```

- [ ] **Step 4: Commit**

```bash
cd /home/nwc/StudioProjects/KNN && git add lib/screens/fuel_price_history.dart && git commit -m "feat: add current prices with weekly change indicators"
```

---

### Task 8: Build Price History Table

**Files:**
- Modify: `lib/screens/fuel_price_history.dart`

- [ ] **Step 1: Replace _buildPriceHistoryTable stub**

```dart
  Widget _buildPriceHistoryTable() {
    // Strip to the most recent records, reverse to chronological order.
    final rows = _history.take(20).toList().reversed.toList();

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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF9FAFB),
                ),
                columnSpacing: 20,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 48,
                columns: const [
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataColumn(label: Text('RON95', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataColumn(label: Text('RON97', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataColumn(label: Text('Diesel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  DataColumn(label: Text('Change', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                ],
                rows: rows.map((p) {
                  final change = _computeTableChange(p);
                  return DataRow(cells: [
                    DataCell(Text(_formatShortDate(p.date), style: const TextStyle(fontSize: 12))),
                    DataCell(Text('${p.ron95.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                    DataCell(Text('${p.ron97.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                    DataCell(Text('${p.diesel.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
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
        ),
      ],
    );
  }

  double? _computeTableChange(FuelPrice p) {
    final idx = _history.indexOf(p);
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
```

- [ ] **Step 2: Commit**

```bash
cd /home/nwc/StudioProjects/KNN && git add lib/screens/fuel_price_history.dart && git commit -m "feat: add price history table"
```

---

### Task 9: Build Insights section

**Files:**
- Modify: `lib/screens/fuel_price_history.dart`

- [ ] **Step 1: Add insight generation helpers**

```dart
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
```

- [ ] **Step 2: Replace _buildInsightsSection stub**

```dart
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
```

- [ ] **Step 3: Commit**

```bash
cd /home/nwc/StudioProjects/KNN && git add lib/screens/fuel_price_history.dart && git commit -m "feat: add insights section with rule-based advice"
```

---

### Task 10: Verify everything compiles

**Files:**
- None

- [ ] **Step 1: Run flutter analyze**

```bash
cd /home/nwc/StudioProjects/KNN && flutter analyze
```

Expected: No errors, no warnings. If any issues, fix and re-run.

- [ ] **Step 2: Commit any final fixes**

```bash
cd /home/nwc/StudioProjects/KNN && git add -A && git commit -m "fix: address analyzer warnings"
```
