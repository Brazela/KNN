import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


final Map<String, BitmapDescriptor> _markerCache = {};


Future<BitmapDescriptor> getNumberedMarker(
  int number, {
  double size = 44,
  Color backgroundColor = const Color(0xFF1A2CC8),
  Color textColor = Colors.white,
}) async {
  // Check cache (keyed by number + size so resizing re-renders).
  final key = '$number-$size';
  if (_markerCache.containsKey(key)) return _markerCache[key]!;

  final devicePixelRatio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
  final canvasSize = (size * devicePixelRatio).round();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Scale factor for high-DPI rendering.
  final scale = devicePixelRatio;
  final sizeScale = size / 44;

  // Outer white border circle.
  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  canvas.drawCircle(
    Offset(canvasSize / 2, canvasSize / 2),
    canvasSize / 2,
    borderPaint,
  );

  // Inner colored circle.
  final innerPaint = Paint()
    ..color = backgroundColor
    ..style = PaintingStyle.fill;
  canvas.drawCircle(
    Offset(canvasSize / 2, canvasSize / 2),
    (canvasSize / 2) - (3 * sizeScale * scale),
    innerPaint,
  );

  // Number text.
  final textPainter = TextPainter(
    text: TextSpan(
      text: '$number',
      style: TextStyle(
        color: textColor,
        fontSize: 16 * sizeScale * scale,
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );
  textPainter.layout();

  textPainter.paint(
    canvas,
    Offset(
      (canvasSize - textPainter.width) / 2,
      (canvasSize - textPainter.height) / 2,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(canvasSize, canvasSize);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final descriptor = BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    imagePixelRatio: devicePixelRatio,
  );

  _markerCache[key] = descriptor;
  return descriptor;
}

/// Cache of generated vehicle-type marker bitmaps.
final Map<String, BitmapDescriptor> _vehicleMarkerCache = {};


Future<BitmapDescriptor> getVehicleMarker(
  String vehicleType, {
  double size = 44,
  bool highlightColor = false,
}) async {
  final cacheKey =
      '${vehicleType.toUpperCase()}${highlightColor ? '_highlight' : ''}';
  if (_vehicleMarkerCache.containsKey(cacheKey)) {
    return _vehicleMarkerCache[cacheKey]!;
  }

  final devicePixelRatio =
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
  final canvasSize = (size * devicePixelRatio).round();
  final scale = devicePixelRatio;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Pick icon and color based on vehicle type.
  IconData iconData;
  Color bgColor;
  final baseType = vehicleType.toUpperCase();
  switch (baseType) {
    case 'BUS':
      iconData = Icons.directions_bus_rounded;
      bgColor = const Color(0xFF1E88E5);
      break;
    case 'SUBWAY':
    case 'METRO':
      iconData = Icons.subway_rounded;
      bgColor = const Color(0xFFE53935);
      break;
    case 'TRAIN':
    case 'RAIL':
    case 'HEAVY_RAIL':
    case 'COMMUTER_TRAIN':
      iconData = Icons.train_rounded;
      bgColor = const Color(0xFFE53935);
      break;
    case 'TRAM':
    case 'LIGHT_RAIL':
      iconData = Icons.tram_rounded;
      bgColor = const Color(0xFFFB8C00);
      break;
    case 'MONORAIL':
      iconData = Icons.mode_fan_off_rounded;
      bgColor = const Color(0xFF8E24AA);
      break;
    default:
      iconData = Icons.directions_transit_rounded;
      bgColor = const Color(0xFF1A2CC8);
  }

  // Override to red when highlighting the nearest vehicle.
  if (highlightColor) {
    bgColor = const Color(0xFFD32F2F);
  }

  // White border circle.
  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  canvas.drawCircle(
    Offset(canvasSize / 2, canvasSize / 2),
    canvasSize / 2,
    borderPaint,
  );

  // Colored inner circle.
  final innerPaint = Paint()
    ..color = bgColor
    ..style = PaintingStyle.fill;
  canvas.drawCircle(
    Offset(canvasSize / 2, canvasSize / 2),
    (canvasSize / 2) - (3 * scale),
    innerPaint,
  );

  // Icon.
  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        color: Colors.white,
        fontSize: 18 * scale,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );
  textPainter.layout();

  textPainter.paint(
    canvas,
    Offset(
      (canvasSize - textPainter.width) / 2,
      (canvasSize - textPainter.height) / 2,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(canvasSize, canvasSize);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final descriptor = BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    imagePixelRatio: devicePixelRatio,
  );

  _vehicleMarkerCache[cacheKey] = descriptor;
  return descriptor;
}
