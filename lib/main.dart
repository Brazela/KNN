import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigation/navigation.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'services/services.dart';

/// App entry point.
void main() {
  runApp(const KNNApp());
}

/// Root widget for the KNN Commute application.
///
/// Provides all service classes via [MultiProvider] and configures the app
/// theme and routing.
class KNNApp extends StatelessWidget {
  /// Creates the root [KNNApp].
  const KNNApp({super.key});

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
        ChangeNotifierProvider<TripProvider>(
          create: (_) => TripProvider(),
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
          fontFamily: 'Roboto',
        ),
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const Homepage(),
      ),
    );
  }
}
