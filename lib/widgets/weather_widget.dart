import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../navigation/app_routes.dart';
import '../utils/constants.dart';
import '../utils/weather_utils.dart';

/// Displays the current weather forecast for the user's location.
///
/// Uses [WeatherService] to fetch today's forecast. Updates on
/// pull-to-refresh via the parent [RefreshIndicator] that calls [onRefresh].
class WeatherWidget extends StatefulWidget {
  /// Creates a [WeatherWidget].
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Weather? _weather;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = context.watch<TripProvider>().currentLocation;
    if (location != null && _weather == null && !_loading) {
      _loadWeather(location);
    }
  }

  /// Fetches the current day's weather forecast.
  Future<void> _loadWeather(Location location) async {
    setState(() {
      _loading = true;
    });

    try {
      final service = context.read<WeatherService>();
      final forecasts = await service.getForecast(
        location.latitude,
        location.longitude,
      );

      if (mounted) {
        setState(() {
          _weather = forecasts.isNotEmpty ? forecasts.first : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load weather: $e')));
      }
    }
  }

  /// Maps a Malay weather summary keyword to a representative emoji.
  String _weatherEmoji(String summary) {
    final lower = summary.toLowerCase();
    if (lower.contains('hujan') && lower.contains('ribut')) return '⛈️';
    if (lower.contains('hujan')) return '🌧️';
    if (lower.contains('ribut') || lower.contains('petir')) return '⛈️';
    if (lower.contains('mendung') || lower.contains('awan')) return '☁️';
    if (lower.contains('cerah') || lower.contains('terang')) return '☀️';
    if (lower.contains('panas')) return '☀️';
    return '🌤️';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _weather == null) {
      return Container(
        height: 100,
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
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_weather == null) {
      return const SizedBox.shrink();
    }

    final weather = _weather!;
    final translatedSummary = translateWeather(weather.summaryForecast);
    final emoji = _weatherEmoji(weather.summaryForecast);

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
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.weatherHistory),
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
              // Emoji + location.
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
                      translatedSummary,
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
              // Min / max temps.
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
  }
}
