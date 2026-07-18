# Fuel Price History Page — Design Spec

## Overview

Add a full-screen Fuel Price History page and a "Details" link on the homepage fuel price widget that navigates to it. The new page displays a line chart of historical prices, current prices with weekly changes, a history table, and rule-based insights.

## Data Source

The existing **data.gov.my JSON API** (`data-catalogue?id=fuelprice`) returns the full history. No Python/parquet pipeline needed.

- **Current URL** (limit=1): `https://api.data.gov.my/data-catalogue?id=fuelprice&sort=-date&limit=1&series_type=level`
- **History URL** (parameterized): same URL with `limit=N` instead of `limit=1`
- Fields returned: `date`, `ron95`, `ron97`, `diesel`, `diesel_eastmsia`, `ron95_skps`, `diesel_budi`, `diesel_skds`, `ron95_budi95`, `series_type`

## Files Changed / Created

| File | Action |
|---|---|
| `pubspec.yaml` | Add `fl_chart: ^0.69.0` |
| `lib/utils/constants.dart` | Update `fuelPriceUrl` to accept limit param; add `fuelPriceHistoryUrl` |
| `lib/services/fuel_price_service.dart` | Add `getFuelPriceHistory(int limit)` method |
| `lib/models/fuel_price.dart` | Add a computed `weeklyChange` field (not stored, derived at display time) |
| `lib/widgets/fuel_price_widget.dart` | Add "Details" text link in header row |
| `lib/navigation/app_routes.dart` | Add `fuelPriceHistory` route constant + switch case |
| `lib/screens/fuel_price_history.dart` | **New** — full-screen page |
| `lib/screens/screens.dart` | Export new screen |

## Detailed Design

### 1. Constants — `lib/utils/constants.dart`

Replace the hardcoded `fuelPriceUrl` with a parameterizable version:

```dart
static const String fuelPriceBaseUrl =
    'https://api.data.gov.my/data-catalogue?id=fuelprice&sort=-date&series_type=level';

static String fuelPriceUrl({int limit = 1}) =>
    '$fuelPriceBaseUrl&limit=$limit';

// For backward compatibility — existing callers keep working.
static String get fuelPriceLatestUrl => fuelPriceUrl();
static String fuelPriceHistoryUrl({int limit = 50}) => fuelPriceUrl(limit: limit);
```

### 2. Service — `lib/services/fuel_price_service.dart`

Add:

```dart
/// Fetches the most recent [limit] fuel price records.
Future<List<FuelPrice>> getFuelPriceHistory({int limit = 50}) async {
  final response = await _client.get(
    Uri.parse(ApiUrls.fuelPriceHistoryUrl(limit: limit)),
  );
  if (response.statusCode != HttpStatus.ok) {
    throw Exception('Failed to fetch fuel price history: ${response.statusCode}');
  }
  final data = jsonDecode(response.body) as List<dynamic>;
  // Filter to only `series_type=level` records (API may mix in change_weekly).
  final levelRecords = data
      .where((e) => (e as Map<String, dynamic>)['series_type'] == 'level')
      .map((e) => FuelPrice.fromJson(e as Map<String, dynamic>))
      .toList();
  if (levelRecords.isEmpty) {
    throw Exception('No level-type fuel price records found');
  }
  return levelRecords;
}
```

Existing `getFuelPrice()` stays unchanged (uses `fuelPriceLatestUrl`).

### 3. Homepage Widget — "Details" Link

In `lib/widgets/fuel_price_widget.dart`, in the header `Row` inside `_buildContent`:

After the `Expanded(child: Text('Fuel Prices'))` and before the date badge, insert:

```dart
TextButton(
  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.fuelPriceHistory),
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

### 4. Routing — `lib/navigation/app_routes.dart`

Add:

```dart
static const String fuelPriceHistory = '/fuel-price-history';
```

In `_buildPage` switch:

```dart
case fuelPriceHistory:
  return const FuelPriceHistoryPage();
```

### 5. New Screen — `lib/screens/fuel_price_history.dart`

**Structure:** `StatefulWidget` following the same init/fetch/error pattern as `ComparisonPage` and `FuelPriceWidget`.

#### State Fields
- `List<FuelPrice> _history = []`
- `bool _loading = true`
- `String? _error`

#### Lifecycle
- `initState()` → `WidgetsBinding.instance.addPostFrameCallback` → `_fetchHistory()`
- `_fetchHistory()` calls `FuelPriceService.getFuelPriceHistory()`, sets state

#### Layout (vertical scroll, matching homepage pattern)

**Section 1: AppBar**
- Leading: back arrow (`Navigator.pop`)
- Title: "Fuel Price History"
- Action: Refresh icon button → `_fetchHistory()`

**Section 2: "📊 Price Trends" — Line Chart**
- `fl_chart` `LineChart` widget
- Three series: RON95 (Yellow), RON97 (Green), Diesel (blue)
- X-axis: dates (abbreviated weeks)
- Y-axis: RM price (1.50–5.00 range, auto-scaled)
- Height: ~220px
- White card container matching app card style

**Section 3: "⛽ Current Prices" — Price Cards**
- Same visual as homepage `FuelPriceWidget._buildContent`:
  - Colored accent bar + label + RM price
- Additional: weekly change indicator for each:
  - ⬆️ green arrow + "+RM X.XX" if price went up
  - ⬇️ red arrow + "-RM X.XX" if price went down
  - ➡️ grey dash + "0.00" if unchanged
- Change computed from `_history[0].ron95 - _history[1].ron95` (latest vs previous)

**Section 4: "📅 Price History Table" — Data Rows**
- Custom table (not Material `DataTable` — too heavy; use `Table` widget or manual rows)
- Columns: Date | RON95 | RON97 | Diesel | Change
- Change row: highlight green for drop, red for rise
- Show ~10 most recent records with scroll for more

**Section 5: "💡 Insights" — Insight Card**
- Simple rule-based text, derived from comparing `_history[0]` vs `_history[1]`:

| Condition | Message |
|---|---|
| All 3 dropped | "RON95, RON97 & Diesel all dropped this week. Great time to fill up!" |
| Any dropped | "RON95 dropped X sen this week." + fill-up advice |
| All unchanged | "Prices unchanged this week." + fill-up advice |
| Any rose | "RON95 rose X sen this week." + fill-up advice |

Fill-up advice by weekday (computed server-side via DateTime):

| Today | Advice |
|---|---|
| Monday | "Fill up before midnight tonight!" |
| Tuesday | "Fill up before midnight tonight!" |
| Wednesday | "Prices updated today." |
| Thursday–Sunday | "Fill up before next Wednesday." |

Combined example:
> 💡 **RON95 dropped 5 sen this week.** Fill up before midnight tonight!

#### Pull-to-refresh
- Wrap body in `RefreshIndicator` that calls `_fetchHistory()`

### 6. Charting Details — `fl_chart`

```dart
LineChart(
  LineChartData(
    gridData: FlGridData(show: false),
    titlesData: FlTitlesData(
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
    ),
    borderData: FlBorderData(show: true, border: Border.all(color: AppColors.border)),
    lineBarsData: [
      _buildLine(data.ron95, Colors.amber),
      _buildLine(data.ron97, Colors.green),
      _buildLine(data.diesel, Colors.blue),
    ],
  ),
)
```

Each series: `LineChartBarData` with `spots`, `isCurved: true`, `dotData: FlDotData(show: false)`, `barWidth: 2`.

## Edge Cases

1. **No history returned** → show error state with retry button (same as homepage widget)
2. **Only 1 record returned** → chart not possible; show message "Not enough data for chart", skip change indicators
3. **Loading state** → shimmer placeholder matching existing pattern
4. **East Malaysia diesel null** → handle gracefully in chart/table (treat as null, skip in table)
5. **API failure** → error state with retry button
6. **Subsidised tiers** → not shown on this page (kept on homepage widget only) to avoid clutter

## Out of Scope

- Subscribed price alerts / push notifications
- Persisting fuel price data locally
- Exporting or sharing price history
- Any GTFS or transit-related changes
