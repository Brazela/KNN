# Weather History Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Weather History page accessible from the homepage weather widget, showing 7-day forecast, persisted weather warnings, and monthly averages via Open-Meteo.

**Architecture:** New `WeatherHistoryPage` screen with three sections. Warnings persisted to a local JSON file via `dart:io` + `path_provider`. Monthly averages fetched from Open-Meteo Historical Archive API (free, no key). Homepage weather widget gets a "Details →" link matching the existing fuel price widget pattern.

**Tech Stack:** Flutter, Provider, http, dart:io, path_provider, Open-Meteo Archive API

## Global Constraints

- Follow existing barrel export pattern: add new files to `lib/screens/screens.dart` and `lib/widgets/widgets.dart`
- Use `@JsonSerializable(fieldRename: FieldRename.snake)` for new models — requires `dart run build_runner build --delete-conflicting-outputs` after model changes
- `http.Client` is injectable in service constructors
- Weather emoji and rain detection logic must be extracted to a shared utility, not duplicated
- Route registration uses switch-case in `AppRoutes._buildPage`

---

### Task 1: Create shared weather utility (`weather_utils.dart`)

**Files:**
- Create: `lib/utils/weather_utils.dart`
- Modify: `lib/utils/constants.dart` (add Open-Meteo URL)

**Interfaces:**
- Consumes: nothing (standalone utility)
- Produces: `String weatherEmoji(String summary)`, `bool hasRainForecast(List<Weather>? forecasts)`, `String dayName(String dateStr)`, `String monthName(int month)` — used by both the existing widgets and the new page

- [ ] **Step 1: Create `lib/utils/weather_utils.dart`**

```dart
import '../models/models.dart';

String weatherEmoji(String summary) {
  final lower = summary.toLowerCase();
  if (lower.contains('hujan') && lower.contains('ribut')) return '⛈️';
  if (lower.contains('hujan')) return '🌧️';
  if (lower.contains('ribut') || lower.contains('petir')) return '⛈️';
  if (lower.contains('mendung') || lower.contains('awan')) return '☁️';
  if (lower.contains('cerah') || lower.contains('terang')) return '☀️';
  if (lower.contains('panas')) return '☀️';
  return '🌤️';
}

bool hasRainForecast(List<Weather>? forecasts) {
  if (forecasts == null || forecasts.isEmpty) return false;
  final first = forecasts.first;
  return weatherEmoji(first.summaryForecast).contains('🌧') ||
      weatherEmoji(first.summaryForecast).contains('⛈');
}

String dayName(String dateStr) {
  final date = DateTime.tryParse(dateStr);
  if (date == null) return '';
  const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  return days[date.weekday % 7];
}

String monthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return months[month - 1];
}
```

- [ ] **Step 2: Add Open-Meteo URL to `lib/utils/constants.dart`**

Find the `ApiUrls` class and add:
```dart
static const String historicalWeatherBaseUrl =
    'https://archive-api.open-meteo.com/v1/archive';
```

- [ ] **Step 3: Verify no imports broken**

Run: `flutter analyze lib/utils/weather_utils.dart` — expect PASS

- [ ] **Step 4: Commit**

```bash
git add lib/utils/weather_utils.dart lib/utils/constants.dart
git commit -m "feat: add shared weather utility functions and Open-Meteo URL"
```

---

### Task 2: Add `MonthlyAverage` model

**Files:**
- Modify: `lib/models/weather.dart`
- Create: `lib/models/weather.g.dart` (via build_runner)

**Interfaces:**
- Consumes: nothing
- Produces: `MonthlyAverage` class with `fromJson`/`toJson` — used by `WeatherService.getHistoricalMonthlyAverage()` and the WeatherHistoryPage

- [ ] **Step 1: Add `MonthlyAverage` class to `lib/models/weather.dart`**

Insert after `EarthquakeWarning` class (before the eof):

```dart
@JsonSerializable(fieldRename: FieldRename.snake)
class MonthlyAverage {
  const MonthlyAverage({
    required this.avgTemp,
    required this.rainDays,
    required this.avgHumidity,
    required this.year,
    required this.month,
    required this.hottestTemp,
    required this.hottestDate,
    required this.coldestTemp,
    required this.coldestDate,
  });

  factory MonthlyAverage.fromJson(Map<String, dynamic> json) =>
      _$MonthlyAverageFromJson(json);

  final double avgTemp;
  final int rainDays;
  final double avgHumidity;
  final int year;
  final int month;
  final double hottestTemp;
  final String hottestDate;
  final double coldestTemp;
  final String coldestDate;

  Map<String, dynamic> toJson() => _$MonthlyAverageToJson(this);

  @override
  String toString() =>
      'MonthlyAverage($year-$month, avgTemp: $avgTemp, rainDays: $rainDays)';
}
```

- [ ] **Step 2: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `weather.g.dart` regenerated with `_$MonthlyAverageFromJson` and `_$MonthlyAverageToJson`

- [ ] **Step 3: Verify model compiles**

Run: `flutter analyze lib/models/weather.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/models/weather.dart lib/models/weather.g.dart
git commit -m "feat: add MonthlyAverage model"
```

---

### Task 3: Add Open-Meteo method + dedup fix to `WeatherService`

**Files:**
- Modify: `lib/services/weather_service.dart`

**Interfaces:**
- Consumes: `MonthlyAverage`, `weather_utils.dart` utilities, `ApiUrls.historicalWeatherBaseUrl`
- Produces: `Future<MonthlyAverage> getHistoricalMonthlyAverage(double lat, double lng, int year, int month)` and deduplicated forecasts from `getForecast()`

- [ ] **Step 1: Add deduplication to `getForecast()`**

In `lib/services/weather_service.dart`, change the return statement to deduplicate by date:

```dart
final seen = <String>{};
return allForecasts
    .where((forecast) => forecast.locationName == districtName)
    .where((forecast) => seen.add(forecast.date))
    .toList();
```

- [ ] **Step 2: Add `getHistoricalMonthlyAverage()` method**

Add after `getEarthquakeWarnings()`:

```dart
Future<MonthlyAverage> getHistoricalMonthlyAverage(
  double latitude,
  double longitude,
  int year,
  int month,
) async {
  final start = '$year-${month.toString().padLeft(2, '0')}-01';
  final lastDay = _daysInMonth(year, month);
  final end = '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

  final uri = Uri.parse(
    '${ApiUrls.historicalWeatherBaseUrl}'
    '?latitude=$latitude&longitude=$longitude'
    '&start_date=$start&end_date=$end'
    '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,'
    'precipitation_hours,relative_humidity_2m_mean'
    '&timezone=Asia/Kuala_Lumpur',
  );

  final response = await _client.get(uri);

  if (response.statusCode != HttpStatus.ok) {
    throw Exception(
      'Failed to fetch historical weather: ${response.statusCode}',
    );
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final daily = data['daily'] as Map<String, dynamic>;
  final times = (daily['time'] as List<dynamic>).cast<String>();
  final maxTemps = (daily['temperature_2m_max'] as List<dynamic>).cast<double>();
  final minTemps = (daily['temperature_2m_min'] as List<dynamic>).cast<double>();
  final precip = (daily['precipitation_sum'] as List<dynamic>)
      .cast<double?>();
  final humidity = (daily['relative_humidity_2m_mean'] as List<dynamic>?)
      ?.cast<double?>() ?? [];

  var sumTemp = 0.0;
  var rainDays = 0;
  var sumHumidity = 0.0;
  var humidityCount = 0;
  var hottestTemp = -double.infinity;
  var coldestTemp = double.infinity;
  var hottestDate = '';
  var coldestDate = '';

  for (var i = 0; i < times.length; i++) {
    final avg = (maxTemps[i] + minTemps[i]) / 2;
    sumTemp += avg;

    if (precip.isNotEmpty && precip[i] != null && precip[i]! > 0) {
      rainDays++;
    }

    if (i < humidity.length && humidity[i] != null) {
      sumHumidity += humidity[i]!;
      humidityCount++;
    }

    if (maxTemps[i] > hottestTemp) {
      hottestTemp = maxTemps[i];
      hottestDate = times[i];
    }
    if (minTemps[i] < coldestTemp) {
      coldestTemp = minTemps[i];
      coldestDate = times[i];
    }
  }

  final count = times.length;
  return MonthlyAverage(
    avgTemp: count > 0 ? (sumTemp / count) : 0,
    rainDays: rainDays,
    avgHumidity: humidityCount > 0 ? (sumHumidity / humidityCount) : 0,
    year: year,
    month: month,
    hottestTemp: hottestTemp,
    hottestDate: hottestDate,
    coldestTemp: coldestTemp,
    coldestDate: coldestDate,
  );
}

int _daysInMonth(int year, int month) {
  if (month == 2) {
    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
  }
  return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
}
```

- [ ] **Step 3: Add `dart:io` import for `HttpStatus` if missing**

Check the file already imports `dart:io` — it uses `HttpStatus` at line 64. If not present, add:
```dart
import 'dart:io';
```

- [ ] **Step 4: Verify service compiles**

Run: `flutter analyze lib/services/weather_service.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/services/weather_service.dart
git commit -m "feat: add Open-Meteo historical monthly average and forecast dedup"
```

---

### Task 4: Add "Details →" link to `WeatherWidget`

**Files:**
- Modify: `lib/widgets/weather_widget.dart`

**Interfaces:**
- Consumes: `AppRoutes.weatherHistory`
- Produces: TextButton "Details →" in the weather card header, matching fuel price widget style

- [ ] **Step 1: Add import for AppRoutes**

Add to existing imports:
```dart
import '../navigation/app_routes.dart';
```

- [ ] **Step 2: Wrap the emoji+location Row with an Expanded and add TextButton**

Current code (lines 119-189) has a `Row` with `children: [Expanded(...), Column(...)]`.

Change to add a "Details →" row above the content, or restructure so the header row contains: `Row(emoji + location name, TextButton)`.

Actually, looking at the current widget it doesn't have a section title like fuel price. The weather widget just shows the card directly. For the "Details →" link, I need to add a title row at the top.

Modify the build method to wrap content in a Column with a header row:

```dart
return Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Weather',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.weatherHistory,
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
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        weather.locationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  weather.summaryForecast,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${weather.minTemp}°',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
              Container(
                width: 30,
                height: 3,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                '${weather.maxTemp}°',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);
```

- [ ] **Step 3: Verify widget compiles**

Run: `flutter analyze lib/widgets/weather_widget.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/weather_widget.dart
git commit -m "feat: add 'Details →' link to WeatherWidget header"
```

---

### Task 5: Register Weather History route

**Files:**
- Modify: `lib/navigation/app_routes.dart`
- Modify: `lib/screens/screens.dart`

- [ ] **Step 1: Add route constant to `AppRoutes`**

Add after `fuelPriceHistory`:
```dart
static const String weatherHistory = '/weather-history';
```

- [ ] **Step 2: Add case to `_buildPage` switch**

Add after the `fuelPriceHistory` case:
```dart
case weatherHistory:
  return const WeatherHistoryPage();
```

- [ ] **Step 3: Add barrel export in `lib/screens/screens.dart`**

Add:
```dart
export 'weather_history_page.dart';
```

- [ ] **Step 4: Commit**

```bash
git add lib/navigation/app_routes.dart lib/screens/screens.dart
git commit -m "feat: register WeatherHistory route"
```

---

### Task 6: Create the `WeatherHistoryPage` screen

**Files:**
- Create: `lib/screens/weather_history_page.dart`
- Modify: `pubspec.yaml` (add `path_provider` dependency if not present)

**Interfaces:**
- Consumes: `WeatherService`, `TripProvider`, `Weather` model, `WeatherWarning` model, `MonthlyAverage` model, `weather_utils.dart`, `AppRoutes.weatherHistory`
- Produces: The full Weather History screen

- [ ] **Step 1: Check if `path_provider` is available**

Run:
```bash
grep -r "path_provider" pubspec.yaml
```
If not found, add:
```yaml
  path_provider: ^2.1.0
```
Then run `flutter pub get`

- [ ] **Step 2: Determine the path_provider availability via transitive deps**

If `path_provider` is already a transitive dependency (check `flutter pub deps`), it can be used directly without adding to pubspec. If not, add it to `pubspec.yaml`.

- [ ] **Step 3: Create `lib/screens/weather_history_page.dart`**

Full file content (organized in sections below):

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation/app_routes.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/constants.dart';
import '../utils/weather_utils.dart';

class WeatherHistoryPage extends StatefulWidget {
  const WeatherHistoryPage({super.key});

  @override
  State<WeatherHistoryPage> createState() => _WeatherHistoryPageState();
}

class _WeatherHistoryPageState extends State<WeatherHistoryPage> {
  Location? _selectedLocation;
  List<Weather> _forecasts = [];
  List<WeatherWarning> _warnings = [];
  List<WeatherWarning> _storedWarnings = [];
  MonthlyAverage? _monthlyAverage;
  bool _loadingForecast = false;
  bool _loadingWarnings = false;
  bool _loadingMonthly = false;
  bool _showAllWarnings = false;
  int _monthlyYear = 0;
  int _monthlyMonth = 0;
  String? _forecastError;
  String? _monthlyError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to previous complete month
    final prev = DateTime(now.year, now.month - 1, 1);
    _monthlyYear = prev.year;
    _monthlyMonth = prev.month;
    _loadLocationAndData();
  }

  Future<void> _loadLocationAndData() async {
    final tripProvider = context.read<TripProvider>();
    final loc = tripProvider.currentLocation;
    if (loc != null && _selectedLocation == null) {
      _selectedLocation = loc;
      await _loadAllData();
    }
  }

  Future<void> _loadAllData() async {
    if (_selectedLocation == null) return;
    await Future.wait([
      _loadForecast(),
      _loadWarningsWithPersistence(),
      _loadMonthlyAverage(),
    ]);
  }

  Future<void> _loadForecast() async {
    setState(() {
      _loadingForecast = true;
      _forecastError = null;
    });
    try {
      final service = context.read<WeatherService>();
      final forecasts = await service.getForecast(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      if (mounted) {
        setState(() {
          _forecasts = forecasts;
          _loadingForecast = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingForecast = false;
          _forecastError = e.toString();
        });
      }
    }
  }

  Future<void> _loadWarningsWithPersistence() async {
    setState(() => _loadingWarnings = true);
    try {
      // Load stored warnings
      final stored = await _readStoredWarnings();
      // Fetch live warnings
      final service = context.read<WeatherService>();
      final live = await service.getWarnings();

      // Merge: add live warnings not already in stored (by issued timestamp)
      final existingIssued = stored.map((w) => w.issued).toSet();
      for (final w in live) {
        if (!existingIssued.contains(w.issued)) {
          stored.add(w);
        }
      }

      // Sort by issued descending (newest first)
      stored.sort((a, b) => b.issued.compareTo(a.issued));

      // Expire warnings older than 90 days
      final cutoff = DateTime.now().subtract(const Duration(days: 90)).toIso8601String();
      stored.removeWhere((w) => w.issued.compareTo(cutoff) < 0);

      // Save back
      await _writeStoredWarnings(stored);

      if (mounted) {
        setState(() {
          _storedWarnings = stored;
          _warnings = live;
          _loadingWarnings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingWarnings = false);
      }
    }
  }

  Future<List<WeatherWarning>> _readStoredWarnings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/weather_warnings.json');
      if (!file.existsSync()) return [];
      final contents = await file.readAsString();
      final list = jsonDecode(contents) as List<dynamic>;
      return list
          .map((e) => WeatherWarning.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeStoredWarnings(List<WeatherWarning> warnings) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/weather_warnings.json');
      final list = warnings.map((w) => w.toJson()).toList();
      await file.writeAsString(jsonEncode(list));
    } catch (_) {
      // Silently fail — persistence is best-effort
    }
  }

  Future<void> _loadMonthlyAverage() async {
    setState(() {
      _loadingMonthly = true;
      _monthlyError = null;
    });
    try {
      final service = context.read<WeatherService>();
      final avg = await service.getHistoricalMonthlyAverage(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        _monthlyYear,
        _monthlyMonth,
      );
      if (mounted) {
        setState(() {
          _monthlyAverage = avg;
          _loadingMonthly = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMonthly = false;
          _monthlyError = e.toString();
        });
      }
    }
  }

  void _selectLocation(Location? location) {
    if (location == null) return;
    setState(() {
      _selectedLocation = location;
      _forecasts = [];
      _monthlyAverage = null;
    });
    _loadAllData();
  }

  void _previousMonth() {
    setState(() {
      if (_monthlyMonth == 1) {
        _monthlyYear--;
        _monthlyMonth = 12;
      } else {
        _monthlyMonth--;
      }
      _monthlyAverage = null;
    });
    _loadMonthlyAverage();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    final nextDate = DateTime(_monthlyYear, _monthlyMonth + 1, 1);
    if (nextDate.isAfter(prev)) return; // Can't go beyond previous month
    setState(() {
      if (_monthlyMonth == 12) {
        _monthlyYear++;
        _monthlyMonth = 1;
      } else {
        _monthlyMonth++;
      }
      _monthlyAverage = null;
    });
    _loadMonthlyAverage();
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final locationName = _selectedLocation?.address ?? 'Current Location';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationSelector(tripProvider),
            const SizedBox(height: 20),
            _buildForecastSection(),
            const SizedBox(height: 20),
            _buildWarningsSection(),
            const SizedBox(height: 20),
            _buildMonthlyAverageSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector(TripProvider tripProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📍 ${_selectedLocation?.address ?? locationName}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _LocationChip(
                label: '📍 Current',
                selected: _selectedLocation == tripProvider.currentLocation,
                onTap: () => _selectLocation(tripProvider.currentLocation),
              ),
              const SizedBox(width: 8),
              _LocationChip(
                label: '🏠 Home',
                selected: _selectedLocation == tripProvider.home,
                onTap: () {
                  if (tripProvider.home != null) {
                    _selectLocation(tripProvider.home);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Set your home location first'),
                        action: SnackBarAction(
                          label: 'Go to Home',
                          onPressed: () =>
                              Navigator.of(context).pushNamed(AppRoutes.home),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              _LocationChip(
                label: '💼 Work',
                selected: _selectedLocation == tripProvider.work,
                onTap: () {
                  if (tripProvider.work != null) {
                    _selectLocation(tripProvider.work);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Set your work location first'),
                        action: SnackBarAction(
                          label: 'Go to Home',
                          onPressed: () =>
                              Navigator.of(context).pushNamed(AppRoutes.home),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              _LocationChip(
                label: '🔍',
                selected: false,
                onTap: () async {
                  final result = await Navigator.of(context).pushNamed(
                    AppRoutes.searchDestination,
                  );
                  if (result != null && result is Location) {
                    _selectLocation(result);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForecastSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 7-Day Forecast',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingForecast)
          const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_forecastError != null)
          _ErrorCard(message: _forecastError!, onRetry: _loadForecast)
        else if (_forecasts.isEmpty)
          const SizedBox(
            height: 180,
            child: Center(child: Text('No forecast data available')),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _forecasts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final f = _forecasts[index];
                final emoji = weatherEmoji(f.summaryForecast);
                return _ForecastDayCard(
                  day: dayName(f.date),
                  date: f.date,
                  emoji: emoji,
                  maxTemp: f.maxTemp,
                  minTemp: f.minTemp,
                  summary: f.summaryForecast,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildWarningsSection() {
    final display = _showAllWarnings ? _storedWarnings : _storedWarnings.take(2).toList();
    final totalCount = _storedWarnings.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚠️ Past Warnings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingWarnings)
          const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_storedWarnings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'No past warnings',
              style: TextStyle(color: AppColors.textMuted),
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ...display.map((w) => _WarningCard(warning: w)),
                if (totalCount > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() => _showAllWarnings = !_showAllWarnings);
                        },
                        icon: Icon(
                          _showAllWarnings
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _showAllWarnings
                              ? 'Show less'
                              : 'Show all $totalCount records',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMonthlyAverageSection() {
    final canGoPrevious = !(_monthlyYear == 1900 && _monthlyMonth == 1);
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    final showing = DateTime(_monthlyYear, _monthlyMonth, 1);
    final canGoNext = showing.isBefore(prev);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '📅 ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: canGoPrevious ? _previousMonth : null,
              iconSize: 20,
            ),
            Text(
              '${monthName(_monthlyMonth)} $_monthlyYear',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: canGoNext ? _nextMonth : null,
              iconSize: 20,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingMonthly)
          const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_monthlyError != null)
          _ErrorCard(message: _monthlyError!, onRetry: _loadMonthlyAverage)
        else if (_monthlyAverage == null)
          const SizedBox.shrink()
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avg Temp: ${_monthlyAverage!.avgTemp.toStringAsFixed(1)}°C  |  '
                  'Rain: ${_monthlyAverage!.rainDays} days  |  '
                  '${_monthlyAverage!.avgHumidity.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hottest: ${_monthlyAverage!.hottestTemp.toStringAsFixed(1)}°C'
                  ' (${_monthlyAverage!.hottestDate.substring(8, 10)} ${monthName(_monthlyAverage!.month).substring(0, 3)})'
                  '  |  '
                  'Coldest: ${_monthlyAverage!.coldestTemp.toStringAsFixed(1)}°C'
                  ' (${_monthlyAverage!.coldestDate.substring(8, 10)} ${monthName(_monthlyAverage!.month).substring(0, 3)})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// --- Sub-widgets ---

class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
    );
  }
}

class _ForecastDayCard extends StatelessWidget {
  const _ForecastDayCard({
    required this.day,
    required this.date,
    required this.emoji,
    required this.maxTemp,
    required this.minTemp,
    required this.summary,
  });

  final String day;
  final String date;
  final String emoji;
  final int maxTemp;
  final int minTemp;
  final String summary;

  @override
  Widget build(BuildContext context) {
    // Extract month/day from date
    final parts = date.split('-');
    final monthDay = parts.length == 3 ? '${parts[2]}/${parts[1]}' : date;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            monthDay,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            '${maxTemp}°',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '${minTemp}°',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.warning});

  final WeatherWarning warning;

  @override
  Widget build(BuildContext context) {
    final date = warning.issued.length >= 10
        ? warning.issued.substring(0, 10)
        : warning.issued;
    final time = warning.issued.length >= 16
        ? warning.issued.substring(11, 16)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warning.titleEn.isNotEmpty ? warning.titleEn : warning.titleBm,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (warning.textEn.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                warning.textEn,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          if (warning.validFrom.length >= 16 && warning.validTo.length >= 16)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 4),
              child: Text(
                'Valid: ${warning.validFrom.substring(11, 16)} - ${warning.validTo.substring(11, 16)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          if (warning.headingEn.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(
                'Affected: ${warning.headingEn}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.orange),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Verify full project compiles**

Run: `flutter analyze lib/screens/weather_history_page.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/screens/weather_history_page.dart pubspec.yaml
git commit -m "feat: create WeatherHistoryPage with forecast, warnings, and monthly averages"
```

---

### Task 7: Final verification

- [ ] **Step 1: Run full flutter analyze**

Run: `flutter analyze`
Expected: No errors or warnings related to new code

- [ ] **Step 2: Run build_runner (if any model changes since)**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: PASS or "Nothing to be done"

- [ ] **Step 3: Commit any remaining changes**

```bash
git add -A
git commit -m "chore: finalize weather history page implementation"
```
