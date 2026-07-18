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
