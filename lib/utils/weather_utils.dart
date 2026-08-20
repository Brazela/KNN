import '../models/models.dart';

/// Returns true when the Malay summary string describes actual rain.
///
/// Correctly excludes negated phrases like "Tiada Hujan" (No rain).
bool isRaining(String summary) {
  final lower = summary.toLowerCase();
  if (lower.contains('tiada hujan') || lower.contains('tiada ribut')) {
    return false;
  }
  return lower.contains('hujan') ||
      lower.contains('ribut') ||
      lower.contains('petir');
}

String weatherEmoji(String summary) {
  final lower = summary.toLowerCase();
  if (lower.contains('tiada hujan')) return '🌤️';
  if (lower.contains('hujan') && lower.contains('ribut')) return '⛈️';
  if (lower.contains('hujan')) return '🌧️';
  if (lower.contains('ribut') || lower.contains('petir')) return '⛈️';
  if (lower.contains('mendung') || lower.contains('awan')) return '☁️';
  if (lower.contains('cerah') || lower.contains('terang')) return '☀️';
  if (lower.contains('panas')) return '☀️';
  return '🌤️';
}

/// Translates a Malay weather summary to English.
String translateWeather(String text) {
  final lower = text.toLowerCase().trim();

  // Whole-phrase matches first.
  if (lower == 'tiada hujan') return 'No rain';
  if (lower == 'hujan ringan') return 'Light rain';
  if (lower == 'hujan sederhana') return 'Moderate rain';
  if (lower == 'hujan lebat') return 'Heavy rain';
  if (lower == 'hujan berpetir') return 'Thunderstorms';
  if (lower == 'hujan ribut') return 'Rain with storm';
  if (lower == 'ribut petir') return 'Thunderstorm';
  if (lower == 'kabus') return 'Foggy';
  if (lower == 'panas') return 'Hot';
  if (lower == 'cerah') return 'Clear';
  if (lower == 'cerah terang') return 'Bright & clear';
  if (lower == 'mendung') return 'Cloudy';
  if (lower == 'berawan') return 'Cloudy';
  if (lower == 'berangin') return 'Windy';

  // Fallback: replace individual keywords so partial matches still work.
  var result = text;
  const replacements = {
    'Tiada hujan': 'No rain',
    'Hujan lebat': 'Heavy rain',
    'Hujan sederhana': 'Moderate rain',
    'Hujan ringan': 'Light rain',
    'Hujan berpetir': 'Thunderstorms',
    'Hujan': 'Rain',
    'Ribut petir': 'Thunderstorm',
    'Ribut': 'Storm',
    'Petir': 'Thunder',
    'Mendung': 'Cloudy',
    'Berawan': 'Cloudy',
    'Cerah terang': 'Bright & clear',
    'Cerah': 'Clear',
    'Panas': 'Hot',
    'Kabus': 'Foggy',
    'Berangin': 'Windy',
    'Pagi': 'Morning',
    'Petang': 'Evening',
    'Malam': 'Night',
    'Tengahari': 'Afternoon',
  };
  for (final entry in replacements.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
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
