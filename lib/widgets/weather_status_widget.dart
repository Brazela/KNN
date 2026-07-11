import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/constants.dart';

/// Displays weather information for the origin, destination, and route
/// as horizontally scrollable compact cards.
class WeatherStatusWidget extends StatelessWidget {
  /// Creates a [WeatherStatusWidget].
  const WeatherStatusWidget({
    this.originWeather,
    this.destinationWeather,
    this.routeForecast,
    super.key,
  });

  /// Weather at the trip origin.
  final Weather? originWeather;

  /// Weather at the trip destination.
  final Weather? destinationWeather;

  /// Forecast along the route (optional).
  final List<Weather>? routeForecast;

  @override
  Widget build(BuildContext context) {
    final hasRain = _hasRainForecast();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasRain)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFDBA74),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Color(0xFFEA580C),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Rain forecasted — expect traffic delays',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(
          height: 108,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (originWeather != null)
                _WeatherCard(
                  label: 'Origin',
                  weather: originWeather!,
                ),
              if (destinationWeather != null)
                _WeatherCard(
                  label: 'Destination',
                  weather: destinationWeather!,
                ),
              if (routeForecast != null && routeForecast!.isNotEmpty)
                _WeatherCard(
                  label: 'Route',
                  weather: routeForecast!.first,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Checks if any forecast contains rain keywords.
  bool _hasRainForecast() {
    final forecasts = <Weather?>[
      originWeather,
      destinationWeather,
      if (routeForecast != null && routeForecast!.isNotEmpty) routeForecast!.first,
    ];

    for (final w in forecasts) {
      if (w == null) continue;
      final summary = w.summaryForecast.toLowerCase();
      if (summary.contains('hujan') ||
          summary.contains('ribut') ||
          summary.contains('petir') ||
          summary.contains('mendung')) {
        return true;
      }
    }
    return false;
  }
}

/// A compact weather card for horizontal scrolling.
class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.label,
    required this.weather,
  });

  final String label;
  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final emoji = _weatherEmoji(weather.summaryForecast);

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      weather.locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            weather.summaryForecast,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${weather.minTemp}°C – ${weather.maxTemp}°C',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
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
}
