import '../models/location.dart';

String shortAddress(Location? location) {
  if (location == null) return 'Unknown';
  final address = location.address ?? '';
  if (address.isEmpty) {
    return '${location.latitude.toStringAsFixed(3)}, ${location.longitude.toStringAsFixed(3)}';
  }
  final parts = address.split(',');
  return parts.first.trim();
}
