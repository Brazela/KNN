import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'helpers.dart';

/// Computes the polyline split point for a journey that first travels from
/// the user's current location to their chosen [from] location.
///
/// Returns the index of the polyline point nearest to [from] (snapping it to
/// the nearest road) and that snapped point.
({int fromPolylineIndex, LatLng snappedFromPoint}) computePreludeSplit({
  required Location from,
  required List<LatLng> polylinePoints,
}) {
  var fromIndex = 0;
  var best = double.infinity;
  for (var i = 0; i < polylinePoints.length; i++) {
    final d = calculateDistance(
      from.latitude,
      from.longitude,
      polylinePoints[i].latitude,
      polylinePoints[i].longitude,
    );
    if (d < best) {
      best = d;
      fromIndex = i;
    }
  }
  final snapped = polylinePoints.isEmpty
      ? LatLng(from.latitude, from.longitude)
      : polylinePoints[fromIndex];
  return (fromPolylineIndex: fromIndex, snappedFromPoint: snapped);
}

/// Prepends a synthetic "Go to {fromLabel}" step to the display step lists so
/// the waypoint (from-location or nearest station) appears as step 1 in the
/// list and as a numbered pin on the map.
({List<String> steps, List<DirectionsStepInfo> stepInfos}) buildPreludeSteps({
  required String fromLabel,
  required List<String> steps,
  required List<DirectionsStepInfo> stepInfos,
  required LatLng snappedFromPoint,
}) {
  final synthetic = DirectionsStepInfo(
    instruction: 'Go to $fromLabel',
    distanceMeters: 0,
    durationSeconds: 0,
    travelMode: 'DRIVING',
    endLatLng: snappedFromPoint,
  );
  return (
    steps: ['Go to $fromLabel', ...steps],
    stepInfos: [synthetic, ...stepInfos],
  );
}