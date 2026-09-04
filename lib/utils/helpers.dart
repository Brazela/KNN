import 'dart:math' show cos, sqrt, asin, pi, sin, atan2;

import 'package:intl/intl.dart';

import '../models/models.dart';

const double _earthRadiusKm = 6371.0;

bool isSameLocation(Location a, Location b) {
  if (a.placeId != null &&
      b.placeId != null &&
      a.placeId!.isNotEmpty &&
      a.placeId == b.placeId) {
    return true;
  }

  const precision = 5;
  final latA = double.parse(a.latitude.toStringAsFixed(precision));
  final lngA = double.parse(a.longitude.toStringAsFixed(precision));
  final latB = double.parse(b.latitude.toStringAsFixed(precision));
  final lngB = double.parse(b.longitude.toStringAsFixed(precision));
  return latA == latB && lngA == lngB;
}

bool isInMalaysia(Location location) {
  final address = location.address;
  if (address != null && address.trim().isNotEmpty) {
    return address.toLowerCase().contains('malaysia');
  }
  final lat = location.latitude;
  final lng = location.longitude;
  final inPeninsular = lat >= 1.0 && lat <= 6.7 && lng >= 99.6 && lng <= 104.6;
  final inEastMalaysia =
      lat >= 0.85 && lat <= 7.4 && lng >= 109.5 && lng <= 119.4;
  return inPeninsular || inEastMalaysia;
}

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

double _degreesToRadians(double degrees) => degrees * pi / 180;

String formatDuration(int minutes) {
  if (minutes < 0) minutes = 0;

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;

  if (hours == 0) return '${remainingMinutes}m';
  if (remainingMinutes == 0) return '${hours}h';
  return '${hours}h ${remainingMinutes}m';
}

String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'ms_MY',
    symbol: 'RM',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

String formatDateTime(DateTime dateTime) {
  return DateFormat('d MMM yyyy, HH:mm').format(dateTime);
}

Duration parseGTFSTime(String time) {
  final parts = time.split(':');
  if (parts.length != 3) return Duration.zero;

  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  final seconds = int.tryParse(parts[2]) ?? 0;

  return Duration(hours: hours, minutes: minutes, seconds: seconds);
}

double bearingBetween(double lat1, double lng1, double lat2, double lng2) {
  final dLng = _degreesToRadians(lng2 - lng1);
  final y = sin(dLng) * cos(_degreesToRadians(lat2));
  final x = cos(_degreesToRadians(lat1)) * sin(_degreesToRadians(lat2)) -
      sin(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * cos(dLng);
  final bearing = atan2(y, x) * 180 / pi;
  return (bearing + 360) % 360;
}
