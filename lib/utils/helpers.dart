import 'dart:math' show cos, sqrt, asin, pi, sin, atan2;

import 'package:intl/intl.dart';

/// Earth radius in kilometres used by the Haversine formula.
const double _earthRadiusKm = 6371.0;

/// Calculates the great-circle distance between two coordinates using the
/// Haversine formula.
///
/// Returns the distance in kilometres.
double calculateDistance(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  final dLat = _degreesToRadians(lat2 - lat1);
  final dLng = _degreesToRadians(lng2 - lng1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLng / 2) *
          sin(dLng / 2);

  final c = 2 * asin(sqrt(a));
  return _earthRadiusKm * c;
}

/// Converts degrees to radians.
double _degreesToRadians(double degrees) => degrees * pi / 180;

/// Formats a duration given in minutes into a human-readable string.
///
/// Examples:
/// - 45  -> "45m"
/// - 90  -> "1h 30m"
/// - 150 -> "2h 30m"
String formatDuration(int minutes) {
  if (minutes < 0) minutes = 0;

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;

  if (hours == 0) return '${remainingMinutes}m';
  if (remainingMinutes == 0) return '${hours}h';
  return '${hours}h ${remainingMinutes}m';
}

/// Formats an amount in Malaysian Ringgit.
///
/// Example: 15.5 -> "RM 15.50"
String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'ms_MY',
    symbol: 'RM',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

/// Formats a [DateTime] into a readable date/time string.
///
/// Example: 10 Jul 2026, 14:30
String formatDateTime(DateTime dateTime) {
  return DateFormat('d MMM yyyy, HH:mm').format(dateTime);
}

/// Formats a [DateTime] into a short date string.
///
/// Example: 10 Jul 2026
String formatDate(DateTime dateTime) {
  return DateFormat('d MMM yyyy').format(dateTime);
}

/// Parses a GTFS time string (HH:MM:SS) into a [Duration] since midnight.
///
/// GTFS times may exceed 23:59:59 for trips running past midnight.
Duration parseGTFSTime(String time) {
  final parts = time.split(':');
  if (parts.length != 3) return Duration.zero;

  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  final seconds = int.tryParse(parts[2]) ?? 0;

  return Duration(hours: hours, minutes: minutes, seconds: seconds);
}

/// Calculates the initial bearing (degrees, 0–360) from point A to point B.
double bearingBetween(double lat1, double lng1, double lat2, double lng2) {
  final dLng = _degreesToRadians(lng2 - lng1);
  final y = sin(dLng) * cos(_degreesToRadians(lat2));
  final x = cos(_degreesToRadians(lat1)) * sin(_degreesToRadians(lat2)) -
      sin(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * cos(dLng);
  final bearing = atan2(y, x) * 180 / pi;
  return (bearing + 360) % 360;
}
