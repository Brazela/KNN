import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'helpers.dart';

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
