/// Category of an [AppNotification].
///
/// Used to filter the Notifications page and to choose each card's icon and
/// colour (see `widgets/notifications/notification_card.dart` — kept out of
/// this file so models stay free of `Widget`/`IconData` dependencies, the
/// same separation already used by every other file in `models/`).
///
/// Line up 1:1 with the two toggles in the Settings > Notifications section
/// (`screens/settings.dart`): [price] and [weather]. Transit and departure
/// categories were removed from both pages together, so this enum and the
/// Settings toggles stay in sync.
enum NotificationCategory {
  /// Fuel or fare price changes.
  price,

  /// Weather warnings along the user's routes.
  weather,
}

/// A single notification shown on the Notifications page.
///
/// Plain, immutable value type for the current UI-mockup phase — see the
/// note on [FavoriteLocation] (`models/favorite_location.dart`) for why this
/// doesn't implement `@JsonSerializable()` yet.
class AppNotification {
  /// Creates an [AppNotification].
  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  /// Unique identifier.
  final String id;

  /// Which category this notification belongs to.
  final NotificationCategory category;

  /// Short headline, e.g. "Heavy rain expected this afternoon".
  final String title;

  /// Full notification body.
  final String message;

  /// When this notification was generated.
  final DateTime timestamp;

  /// Whether the user has opened/read this notification.
  final bool isRead;

  /// Returns a copy of this notification with the given fields replaced.
  ///
  /// Used to flip [isRead] without mutating the original in place.
  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      category: category,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
