import 'package:flutter/material.dart';

import '../models/models.dart';
import '../screens/screens.dart';

/// Route name constants used throughout the app.
abstract class AppRoutes {
  /// Home route.
  static const String home = '/';

  /// Search destination route.
  static const String searchDestination = '/search-destination';

  /// Origin selection route.
  static const String originSelection = '/origin-selection';

  /// Transit vs driving comparison route.
  static const String comparison = '/comparison';

  /// Detailed route view.
  static const String routeDetails = '/route-details';

  /// Live vehicle tracking route.
  static const String liveTracking = '/live-tracking';

  /// Trip history route.
  static const String tripHistory = '/trip-history';

  /// Saved favorites route.
  static const String favorites = '/favorites';

  /// Notifications route.
  static const String notifications = '/notifications';

  /// Settings route.
  static const String settings = '/settings';

  /// Alerts and emergency route.
  static const String alertsEmergency = '/alerts-emergency';

  /// User profile route.
  static const String profile = '/profile';

  /// Generates a route for the given [RouteSettings].
  ///
  /// Routes that do not yet have a dedicated screen return a placeholder
  /// "Coming Soon" page so the app remains compilable and navigable.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (context) => _buildPage(settings.name, settings.arguments),
    );
  }

  /// Builds the widget for a named route.
  ///
  /// TODO: Replace remaining placeholder pages with real screen
  /// implementations.
  static Widget _buildPage(String? name, Object? arguments) {
    switch (name) {
      case home:
      // Home is provided by the initial route in main.dart.
        return const _PlaceholderPage(title: 'Home');
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
      case tripHistory:
        return const _PlaceholderPage(title: 'Trip History');
      case favorites:
        return const FavoritesPage();
      case notifications:
        return const NotificationsPage();
      case settings:
        return const SettingsPage();
      case alertsEmergency:
        return const _PlaceholderPage(title: 'Alerts & Emergency');
      case profile:
        return const _PlaceholderPage(title: 'Profile');
      default:
        return const _PlaceholderPage(title: 'Page Not Found');
    }
  }
}

/// Temporary placeholder page for routes without a dedicated screen.
class _PlaceholderPage extends StatelessWidget {
  /// Creates a [_PlaceholderPage].
  const _PlaceholderPage({required this.title});

  /// Page title shown in the app bar.
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
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
