import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class NotificationService {
  static const _storeKey = 'notifications';
  static const _lastFuelKey = 'last_fuel_price';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    await _createChannels();
  }

  Future<void> _createChannels() async {
    const price = AndroidNotificationChannel(
      'price_alerts',
      'Price Alerts',
      description: 'Fuel and fare price changes',
      importance: Importance.high,
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(price);
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<void> show(AppNotification notification) async {
    const channel = 'price_alerts';
    const channelName = 'Price Alerts';
    await _plugin.show(
      id: notification.id.hashCode & 0x7fffffff,
      title: notification.title,
      body: notification.message,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
    await add(notification);
  }

  Future<List<AppNotification>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(AppNotification notification) async {
    final list = await load();
    list.insert(0, notification);
    await _save(list);
  }

  Future<void> delete(String id) async {
    final list = await load();
    await _save(list.where((n) => n.id != id).toList());
  }

  Future<void> clearAll() async {
    await _save([]);
  }

  Future<void> markRead(String id) async {
    final list = await load();
    await _save([
      for (final n in list) if (n.id == id) n.copyWith(isRead: true) else n,
    ]);
  }

  Future<void> markAllRead() async {
    final list = await load();
    await _save([for (final n in list) n.copyWith(isRead: true)]);
  }

  Future<void> _save(List<AppNotification> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, jsonEncode(list.map((n) => n.toJson()).toList()));
  }

  Future<FuelPrice?> lastFuelPrice() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastFuelKey);
    if (raw == null) return null;
    return FuelPrice.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveLastFuelPrice(FuelPrice price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFuelKey, jsonEncode(price.toJson()));
  }
}
