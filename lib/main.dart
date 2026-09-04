import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'navigation/navigation.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'services/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.init();
  await Workmanager().initialize(notificationBackgroundTask);
  await Workmanager().registerPeriodicTask(
    'knn-notification-check',
    'notificationCheck',
    frequency: const Duration(hours: 6),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
  unawaited(notificationService.requestPermission());
  unawaited(runNotificationCheck());
  unawaited(syncHistory());
  runApp(KNNApp(notificationService: notificationService));
}

class KNNApp extends StatelessWidget {

  const KNNApp({super.key, required this.notificationService});

  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<GTFSService>(create: (_) => GTFSService()),
        Provider<WeatherService>(create: (_) => WeatherService()),
        Provider<FuelPriceService>(create: (_) => FuelPriceService()),
        Provider<GoogleMapsService>(create: (_) => GoogleMapsService()),
        Provider<NativePlacesService>(create: (_) => NativePlacesService()),
        Provider<LocationService>(create: (_) => const LocationService()),
        Provider<TripHistoryService>(create: (_) => TripHistoryService()),
        Provider<SavedPlacesService>(create: (_) => SavedPlacesService()),
        Provider<NotificationService>(create: (_) => notificationService),
        ChangeNotifierProvider<SettingsService>(
          create: (context) => SettingsService()..load(),
        ),
        ChangeNotifierProvider<TripProvider>(
          create: (context) {
            final provider = TripProvider();
            final historyService = context.read<TripHistoryService>();
            provider.initHistoryService(historyService);
            provider.initSavedPlaces(context.read<SavedPlacesService>());
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'KNN Commute',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF2F3F7),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A2CC8),
            brightness: Brightness.light,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2CC8),
              foregroundColor: Colors.white,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A2CC8),
              foregroundColor: Colors.white,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1A2CC8),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A2CC8),
              side: const BorderSide(color: Color(0xFF1A2CC8)),
            ),
          ),
          fontFamily: 'Roboto',
        ),
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const Homepage(),
      ),
    );
  }
}
