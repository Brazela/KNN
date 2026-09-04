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
import 'location_picker_page.dart';

class WeatherHistoryPage extends StatefulWidget {
  const WeatherHistoryPage({super.key});

  @override
  State<WeatherHistoryPage> createState() => _WeatherHistoryPageState();
}

class _WeatherHistoryPageState extends State<WeatherHistoryPage> {
  Location? _selectedLocation;
  String _locationSource = '';
  List<Weather> _forecasts = [];
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
  int _loadToken = 0;

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
    // Warnings are national data — load once per page visit.
    // ignore: discarded_futures
    _loadWarningsWithPersistence();

    final tripProvider = context.read<TripProvider>();
    final loc = tripProvider.currentLocation;
    if (loc != null && _selectedLocation == null) {
      _selectedLocation = loc;
      _locationSource = 'Current';
      await _loadAllData();
    }
  }

  Future<void> _loadAllData() async {
    if (_selectedLocation == null) return;
    await Future.wait([
      _loadForecast(),
      _loadMonthlyAverage(),
    ]);
  }

  Future<void> _refreshAll() async {
    _loadToken++;
    await _loadAllData();
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('429')) {
      return 'Weather data temporarily unavailable — please try again in a minute.';
    }
    return s;
  }

  Future<void> _loadForecast() async {
    final token = _loadToken;
    setState(() {
      _loadingForecast = true;
      _forecastError = null;
    });
    try {
      final service = context.read<WeatherService>();
      final forecasts = await service.getForecast(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        useCache: _locationSource != 'Current',
      );
      if (!mounted || token != _loadToken) return;
      setState(() {
        _forecasts = forecasts;
        _loadingForecast = false;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _loadingForecast = false;
        _forecastError = _friendlyError(e);
      });
    }
  }

  Future<void> _loadWarningsWithPersistence() async {
    setState(() => _loadingWarnings = true);

    final service = context.read<WeatherService>();
    // Always load persisted warnings first (safe outside try-catch)
    final stored = await _readStoredWarnings();

    try {
      // Fetch live warnings
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
    } catch (_) {
      // Live fetch failed — persisted warnings still display below
    }

    if (mounted) {
      setState(() {
        _storedWarnings = stored;
        _loadingWarnings = false;
      });
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
    final token = _loadToken;
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
      if (!mounted || token != _loadToken) return;
      setState(() {
        _monthlyAverage = avg;
        _loadingMonthly = false;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _loadingMonthly = false;
        _monthlyError = _friendlyError(e);
      });
    }
  }

  void _selectLocation(Location? location, {String source = ''}) {
    if (location == null) return;
    setState(() {
      _selectedLocation = location;
      _locationSource = source;
      _loadToken++;
      _forecasts = [];
      _monthlyAverage = null;
    });
    _loadAllData();
  }

  Future<void> _showNotSetDialog({
    required String title,
    required String content,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed(AppRoutes.home);
            },
            child: const Text(
              'Go to Home',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationErrorDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Could not get location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(String dateStr) {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return dateStr == todayStr;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: (_loadingForecast || _loadingMonthly) ? null : _refreshAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }

  Widget _buildLocationSelector(TripProvider tripProvider) {
    final sourceLabel = switch (_locationSource) {
      'Current' => 'Current',
      'Home' => 'Home',
      'Work' => 'Work',
      _ => _selectedLocation == null ? 'Current Location' : 'Selected Location',
    };
    final subtitle = _selectedLocation?.address ??
        (_selectedLocation != null
            ? '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '📍 ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sourceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null && _selectedLocation != null)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _LocationChip(
                label: '📍 Current',
                selected: _selectedLocation == tripProvider.currentLocation &&
                    _locationSource == 'Current',
                onTap: () async {
                  var loc = tripProvider.currentLocation;
                  if (loc == null) {
                    final locationService = context.read<LocationService>();
                    try {
                      final deviceLoc =
                          await locationService.getCurrentLocation();
                      if (!mounted) return;
                      tripProvider.setCurrentLocation(deviceLoc);
                      loc = deviceLoc;
                    } catch (e) {
                      if (!mounted) return;
                      await _showLocationErrorDialog(e.toString());
                      return;
                    }
                  }
                  _selectLocation(loc, source: 'Current');
                },
              ),
              const SizedBox(width: 8),
              _LocationChip(
                label: '🏠 Home',
                selected: _selectedLocation == tripProvider.home &&
                    _locationSource == 'Home',
                onTap: () {
                  if (tripProvider.home != null) {
                    _selectLocation(tripProvider.home, source: 'Home');
                  } else {
                    _showNotSetDialog(
                      title: 'Home not set',
                      content:
                          'Set your home location to quickly check weather for it.',
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              _LocationChip(
                label: '💼 Work',
                selected: _selectedLocation == tripProvider.work &&
                    _locationSource == 'Work',
                onTap: () {
                  if (tripProvider.work != null) {
                    _selectLocation(tripProvider.work, source: 'Work');
                  } else {
                    _showNotSetDialog(
                      title: 'Work not set',
                      content:
                          'Set your work location to quickly check weather for it.',
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              _LocationChip(
                label: '🔍',
                selected: false,
                onTap: () async {
                  final result = await Navigator.of(context).push<Location>(
                    MaterialPageRoute(
                      builder: (_) => const LocationPickerPage(),
                    ),
                  );
                  if (result != null) {
                    _selectLocation(result, source: 'Search');
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
    // Week range for temp bar scaling
    int? weekMin;
    int? weekMax;
    if (_forecasts.isNotEmpty) {
      weekMin = _forecasts.map((f) => f.minTemp).reduce((a, b) => a < b ? a : b);
      weekMax = _forecasts.map((f) => f.maxTemp).reduce((a, b) => a > b ? a : b);
    }

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
        if (_forecasts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Forecast for ${_forecasts.first.locationName} district · Source: data.gov.my',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (_loadingForecast)
          Container(
            height: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_forecastError != null)
          _ErrorCard(message: _forecastError!, onRetry: _loadForecast)
        else if (_forecasts.isEmpty)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(child: Text('No forecast data available')),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _forecasts.length; i++) ...[
                  _ForecastRow(
                    forecast: _forecasts[i],
                    isToday: _isToday(_forecasts[i].date),
                    weekMin: weekMin!,
                    weekMax: weekMax!,
                  ),
                  if (i < _forecasts.length - 1)
                    const Divider(height: 1, indent: 12, endIndent: 12),
                ],
              ],
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('📅', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 8),
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
        const SizedBox(height: 2),
        const Text(
          'Historical monthly averages · Source: Open-Meteo',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: '🌡️',
                          value: '${_monthlyAverage!.avgTemp.toStringAsFixed(1)}°C',
                          label: 'Avg Temperature',
                        ),
                      ),
                      Container(width: 1, height: 64, color: AppColors.border),
                      Expanded(
                        child: _StatTile(
                          icon: '🌧️',
                          value: '${_monthlyAverage!.rainDays}',
                          label: 'Rain Days',
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: '💧',
                          value: '${_monthlyAverage!.avgHumidity.toStringAsFixed(0)}%',
                          label: 'Avg Humidity',
                        ),
                      ),
                      Container(width: 1, height: 64, color: AppColors.border),
                      Expanded(
                        child: _StatTile(
                          icon: '📈',
                          value:
                              '${_monthlyAverage!.coldestTemp.toStringAsFixed(1)}° / ${_monthlyAverage!.hottestTemp.toStringAsFixed(1)}°',
                          label: 'Min / Max',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    'Hottest ${_monthlyAverage!.hottestTemp.toStringAsFixed(1)}° on ${_formatMonthDay(_monthlyAverage!.hottestDate)}  ·  '
                    'Coldest ${_monthlyAverage!.coldestTemp.toStringAsFixed(1)}° on ${_formatMonthDay(_monthlyAverage!.coldestDate)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatMonthDay(String isoDate) {
    if (isoDate.length < 10) return isoDate;
    final day = isoDate.substring(8, 10);
    final mon = int.tryParse(isoDate.substring(5, 7)) ?? _monthlyMonth;
    return '$day ${monthName(mon).substring(0, 3)}';
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
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
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

class _ForecastRow extends StatelessWidget {
  const _ForecastRow({
    required this.forecast,
    required this.isToday,
    required this.weekMin,
    required this.weekMax,
  });

  final Weather forecast;
  final bool isToday;
  final int weekMin;
  final int weekMax;

  @override
  Widget build(BuildContext context) {
    final parts = forecast.date.split('-');
    final monthDay = parts.length == 3 ? '${parts[2]}/${parts[1]}' : forecast.date;
    final emoji = weatherEmoji(forecast.summaryForecast);
    final condition = translateWeather(forecast.summaryForecast);
    final rainy = isRaining(forecast.summaryForecast);
    final dayLabel = dayName(forecast.date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rainy ? const Color(0xFFF0F5FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Date column
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                else
                  Text(
                    dayLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  monthDay,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Emoji + condition
          Expanded(
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    condition,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Min temp
          Text(
            '${forecast.minTemp}°',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 6),
          // Range bar
          SizedBox(
            width: 72,
            child: _TempRangeBar(
              minTemp: forecast.minTemp,
              maxTemp: forecast.maxTemp,
              weekMin: weekMin,
              weekMax: weekMax,
            ),
          ),
          const SizedBox(width: 6),
          // Max temp
          Text(
            '${forecast.maxTemp}°',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TempRangeBar extends StatelessWidget {
  const _TempRangeBar({
    required this.minTemp,
    required this.maxTemp,
    required this.weekMin,
    required this.weekMax,
  });

  final int minTemp;
  final int maxTemp;
  final int weekMin;
  final int weekMax;

  @override
  Widget build(BuildContext context) {
    final span = (weekMax - weekMin).clamp(1, 1000);
    final leftFlex = ((minTemp - weekMin) / span * 100).round().clamp(0, 100);
    final widthFlex = ((maxTemp - minTemp) / span * 100).round().clamp(1, 100);
    final rightFlex = (100 - leftFlex - widthFlex).clamp(0, 100);

    return SizedBox(
      height: 6,
      child: Row(
        children: [
          if (leftFlex > 0) Expanded(flex: leftFlex, child: const SizedBox()),
          Expanded(
            flex: widthFlex,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFFFFA726)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (rightFlex > 0) Expanded(flex: rightFlex, child: const SizedBox()),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
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
