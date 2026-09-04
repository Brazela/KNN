import 'package:flutter/material.dart';

import '../models/models.dart';
import '../screens/screens.dart';

abstract class AppRoutes {

  static const String home = '/';

  static const String searchDestination = '/search-destination';

  static const String originSelection = '/origin-selection';

  static const String comparison = '/comparison';

  static const String routeDetails = '/route-details';

  static const String liveTracking = '/live-tracking';

  static const String tripHistory = '/trip-history';

  static const String favorites = '/favorites';

  static const String notifications = '/notifications';

  static const String settings = '/settings';

  static const String nearbyServices = '/nearby-services';

  static const String fuelPriceHistory = '/fuel-price-history';

  static const String weatherHistory = '/weather-history';

  static const String parkingLocator = '/parking-locator';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (context) => _buildPage(settings.name, settings.arguments),
    );
  }

  static Widget _buildPage(String? name, Object? arguments) {
    switch (name) {
      case home:
        return const Homepage();
      case searchDestination:
        return SearchDestinationPage(
          initialPlace: arguments is NearbyPlace ? arguments : null,
        );
      case originSelection:
        return const OriginSelectionPage();
      case comparison:
        return const ComparisonPage();
      case routeDetails:
        return const RouteDetailsPage();
      case liveTracking:
        return const LiveTrackingPage();
      case fuelPriceHistory:
        return const FuelPriceHistoryPage();
      case weatherHistory:
        return const WeatherHistoryPage();
      case tripHistory:
        return const TripHistoryPage();
      case favorites:
        return const FavoritesPage();
      case notifications:
        return const NotificationsPage();
      case settings:
        return const SettingsPage();
      case nearbyServices:
        return const NearbyServicesPage();
      case parkingLocator:
        return const ParkingLocatorPage();
      default:
        return const _PlaceholderPage(title: 'Page Not Found');
    }
  }
}

class _PlaceholderPage extends StatelessWidget {

  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
