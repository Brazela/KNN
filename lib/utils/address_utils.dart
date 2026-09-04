import '../models/location.dart';

String shortAddress(Location? location) {
  if (location == null) return 'Unknown';
  final address = location.address ?? '';
  if (address.isEmpty) {
    return '${location.latitude.toStringAsFixed(3)}, ${location.longitude.toStringAsFixed(3)}';
  }
  final parts = address.split(',').map((p) => p.trim()).toList();
  for (final part in parts) {
    if (_isMeaningfulName(part)) return part;
  }
  return parts.first;
}

bool _isMeaningfulName(String s) {
  if (s.isEmpty) return false;

  if (RegExp(r'^\d+$').hasMatch(s)) return false;

  if (RegExp(r'^[A-Za-z]{0,3}\d+([-–/]\w*)?$').hasMatch(s)) return false;

  if (RegExp(r'^(No\.?|Lot|Unit)\s+\d+').hasMatch(s)) return false;

  return RegExp(r'[A-Za-z]{2}').hasMatch(s);
}
