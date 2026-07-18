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
      if (!mounted) return;
      setState(() {
        _forecasts = forecasts;
        _loadingForecast = false;
      });
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

    // Always load persisted warnings first (safe outside try-catch)
    final stored = await _readStoredWarnings();

    try {
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
          '📍 ${_selectedLocation?.address ?? 'Current Location'}',
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
              separatorBuilder: (_, _) => const SizedBox(width: 10),
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
            '$maxTemp°',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '$minTemp°',
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
