import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Service responsible for fetching weather forecasts, warnings, and earthquake
/// reports from data.gov.my.
class WeatherService {
  /// Creates a [WeatherService].
  ///
  /// An optional [http.Client] can be injected for testing.
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Hardcoded lookup of major Malaysian district coordinates.
  ///
  /// The data.gov.my forecast API returns forecasts by district name without
  /// coordinates, so we use this map to match the nearest district to a given
  /// lat/lng. Expand this map to improve coverage.
  static const Map<String, List<double>> _districtCoordinates = {
    'Kuala Lumpur': [3.139, 101.6869],
    'Petaling Jaya': [3.1073, 101.6067],
    'Shah Alam': [3.0733, 101.5185],
    'Klang': [3.0449, 101.4456],
    'Putrajaya': [2.9264, 101.6964],
    'Cyberjaya': [2.9225, 101.6509],
    'George Town': [5.4141, 100.3288],
    'Bayan Lepas': [5.2961, 100.275],
    'Butterworth': [5.3991, 100.3638],
    'Johor Bahru': [1.4927, 103.7414],
    'Iskandar Puteri': [1.4296, 103.613],
    'Skudai': [1.5347, 103.6577],
    'Ipoh': [4.5975, 101.0901],
    'Taiping': [4.8519, 100.7408],
    'Kuala Terengganu': [5.3296, 103.137],
    'Kota Bharu': [6.1254, 102.2383],
    'Kuantan': [3.8077, 103.326],
    'Kuala Lipis': [4.1842, 102.0544],
    'Seremban': [2.7259, 101.9378],
    'Melaka': [2.2008, 102.2438],
    'Alor Setar': [6.1248, 100.3678],
    'Kangar': [6.4414, 100.1986],
    'Kota Kinabalu': [5.9804, 116.0735],
    'Kuching': [1.5535, 110.3593],
    'Miri': [4.3995, 113.9914],
    'Sibu': [2.2873, 111.8307],
  };

  /// Fetches the 7-day weather forecast for the district nearest to the given
  /// coordinates.
  ///
  /// The API returns forecasts for all districts; this method matches the
  /// closest district using [_districtCoordinates].
  ///
  /// Returns a list of [Weather] forecasts starting from today.
  /// Throws an exception if the request fails.
  Future<List<Weather>> getForecast(double latitude, double longitude) async {
    final response = await _client.get(Uri.parse(ApiUrls.weatherForecastUrl));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to fetch weather forecast: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    final allForecasts = data
        .map((json) => Weather.fromJson(json as Map<String, dynamic>))
        .toList();

    final districtName = _findNearestDistrict(latitude, longitude);

    return allForecasts
        .where((forecast) => forecast.locationName == districtName)
        .toList();
  }

  /// Finds the nearest known district name to the given coordinates.
  String _findNearestDistrict(double latitude, double longitude) {
    String? nearest;
    var bestDistance = double.infinity;

    for (final entry in _districtCoordinates.entries) {
      final coords = entry.value;
      final distance = calculateDistance(
        latitude,
        longitude,
        coords[0],
        coords[1],
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = entry.key;
      }
    }

    return nearest ?? 'Kuala Lumpur';
  }

  /// Fetches active weather warnings from data.gov.my.
  ///
  /// Returns a list of [WeatherWarning].
  /// Throws an exception if the request fails.
  Future<List<WeatherWarning>> getWarnings() async {
    final response = await _client.get(Uri.parse(ApiUrls.weatherWarningUrl));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to fetch weather warnings: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => WeatherWarning.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches earthquake warnings/reports from data.gov.my.
  ///
  /// Returns a list of [EarthquakeWarning].
  /// Throws an exception if the request fails.
  Future<List<EarthquakeWarning>> getEarthquakeWarnings() async {
    final response =
        await _client.get(Uri.parse(ApiUrls.earthquakeWarningUrl));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to fetch earthquake warnings: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => EarthquakeWarning.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
