import 'package:workmanager/workmanager.dart';

import '../models/models.dart';
import 'fuel_price_service.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';

@pragma('vm:entry-point')
void notificationBackgroundTask() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await runNotificationCheck();
      await syncHistory();
    } catch (_) {}
    return true;
  });
}

Future<void> runNotificationCheck() async {
  final settings = SettingsService();
  await settings.load();
  final notifications = NotificationService();
  await notifications.init();

  if (settings.priceAlerts) {
    try {

      final history = await FuelPriceService().getFuelPriceHistory(limit: 4);
      if (history.isEmpty) return;
      final latest = history.first;
      final last = await notifications.lastFuelPrice();
      if (last == null || last.date != latest.date) {
        final previous = history.length > 1 ? history[1] : null;
        await notifications.show(AppNotification(
          id: 'fuel-${DateTime.now().millisecondsSinceEpoch}',
          category: NotificationCategory.price,
          title: 'Fuel prices updated',
          message: _buildFuelPriceMessage(latest, previous, history),
          timestamp: DateTime.now(),
        ));
        await notifications.saveLastFuelPrice(latest);
      }
    } catch (_) {}
  }
}

String _buildFuelPriceMessage(
  FuelPrice latest,
  FuelPrice? previous,
  List<FuelPrice> history,
) {
  final buffer = StringBuffer('Effective ${_formatFuelDate(latest.date)}\n');

  buffer.writeln(_priceLine('RON95', latest.ron95, previous?.ron95));
  buffer.writeln(_priceLine('RON97', latest.ron97, previous?.ron97));
  buffer.writeln(_priceLine('Diesel', latest.diesel, previous?.diesel));

  final past = history.length > 1 ? history.sublist(1) : const <FuelPrice>[];
  if (past.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('Previous:');
    for (final p in past.take(3)) {
      buffer.writeln(
        '${_formatFuelDate(p.date)}: '
        'RON95 ${p.ron95.toStringAsFixed(2)} | '
        'RON97 ${p.ron97.toStringAsFixed(2)} | '
        'Diesel ${p.diesel.toStringAsFixed(2)}',
      );
    }
  }
  return buffer.toString().trimRight();
}

String _priceLine(String label, double price, double? previous) {
  final base = '$label: RM${price.toStringAsFixed(2)}/L';
  if (previous == null) return base;
  final delta = price - previous;
  final arrow = delta < 0 ? '▼' : (delta > 0 ? '▲' : '•');
  return '$base ($arrow${delta.abs().toStringAsFixed(2)})';
}

String _formatFuelDate(String dateStr) {
  final parsed = DateTime.tryParse(dateStr);
  if (parsed == null) return dateStr;
  final d = parsed.day.toString().padLeft(2, '0');
  final m = parsed.month.toString().padLeft(2, '0');
  return '$d/$m/${parsed.year}';
}

Future<void> syncHistory() async {
  final storage = LocalStorageService();
  try {
    final fuelHistory =
        await FuelPriceService().getFuelPriceHistory(limit: 12);
    await storage.saveFuelHistory(fuelHistory);
  } catch (_) {}
}
