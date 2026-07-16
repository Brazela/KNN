import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Cache of generated numbered marker bitmaps to avoid rebuilding.
final Map<int, BitmapDescriptor> _markerCache = {};

/// Generates a [BitmapDescriptor] for a numbered circle marker, styled
/// like Google Maps checkpoint markers.
///
/// [number] is the step number (1-based). [size] is the marker diameter
/// in logical pixels (default 44). The result is cached so repeated
/// calls for the same number are cheap.
Future<BitmapDescriptor> getNumberedMarker(
  int number, {
  double size = 44,
  Color backgroundColor = const Color(0xFF1A2CC8),
  Color textColor = Colors.white,
}) async {
  // Check cache.
  final key = number;
  if (_markerCache.containsKey(key)) return _markerCache[key]!;

  final devicePixelRatio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
  final canvasSize = (size * devicePixelRatio).round();

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Scale factor for high-DPI rendering.
  final scale = devicePixelRatio;

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
    (canvasSize / 2) - (3 * scale),
    innerPaint,
  );

  // Number text.
  final textPainter = TextPainter(
    text: TextSpan(
      text: '$number',
      style: TextStyle(
        color: textColor,
        fontSize: 16 * scale,
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
  final descriptor = BitmapDescriptor.fromBytes(
    bytes!.buffer.asUint8List(),
  );

  _markerCache[key] = descriptor;
  return descriptor;
}
