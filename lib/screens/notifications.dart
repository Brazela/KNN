import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/constants.dart';
import '../widgets/widgets.dart';

/// Notifications feed — price, weather, transit, and departure alerts.
///
/// UI-mockup implementation: [_notifications] is seeded with local,
/// in-memory dummy data covering all four categories listed in MAD.docx.
/// Nothing is persisted yet; this is tracked as the Local Database module.
///
/// No wireframe exists for this page — MAD.docx explicitly notes "NO IMAGE
/// FOR NOTIFICATION PAGE" — so the layout follows the feature list (price /
/// weather / transit / departure alerts, mark-all-read) using the same
/// header, card, and spacing patterns established by the rest of the app.
class NotificationsPage extends StatefulWidget {
  /// Creates a [NotificationsPage].
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<AppNotification> _notifications = _dummyNotifications();
  NotificationCategory? _activeFilter;

  static List<AppNotification> _dummyNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        category: NotificationCategory.weather,
        title: 'Heavy rain expected this afternoon',
        message: 'Driving time to KL Sentral may double. Transit is the '
            'more reliable option today.',
        timestamp: now.subtract(const Duration(minutes: 12)),
      ),
      AppNotification(
        id: 'n2',
        category: NotificationCategory.price,
        title: 'Fuel prices updated',
        message:
            'RON95 is now RM2.05/L this week, down 2 sen from last week.',
        timestamp: now.subtract(const Duration(hours: 6)),
        isRead: true,
      ),
    ];
  }

  List<AppNotification> get _visibleNotifications {
    if (_activeFilter == null) return _notifications;
    return _notifications.where((n) => n.category == _activeFilter).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAsRead(AppNotification notification) {
    if (notification.isRead) return;
    setState(() {
      _notifications = [
        for (final n in _notifications)
          if (n.id == notification.id) n.copyWith(isRead: true) else n,
      ];
    });
  }

  void _markAllRead() {
    setState(() {
      _notifications = [
        for (final n in _notifications) n.copyWith(isRead: true),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final hPad = isWide ? 40.0 : 20.0;
            const maxW = 480.0;

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildFilterRow(),
                      const SizedBox(height: 16),
                      if (_visibleNotifications.isEmpty)
                        const _EmptyState()
                      else
                        for (final notification in _visibleNotifications) ...[
                          NotificationCard(
                            notification: notification,
                            onTap: () => _markAsRead(notification),
                          ),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_unreadCount > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '$_unreadCount unread',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        TextButton(
          onPressed: _unreadCount > 0 ? _markAllRead : null,
          child: const Text(
            'Mark all read',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          CategoryFilterChip(
            label: 'All',
            selected: _activeFilter == null,
            onTap: () => setState(() => _activeFilter = null),
          ),
          for (final category in NotificationCategory.values) ...[
            const SizedBox(width: 8),
            CategoryFilterChip(
              label: _categoryLabel(category),
              selected: _activeFilter == category,
              onTap: () => setState(() => _activeFilter = category),
            ),
          ],
        ],
      ),
    );
  }

  String _categoryLabel(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.price:
        return 'Price';
      case NotificationCategory.weather:
        return 'Weather';
    }
  }
}

/// Placeholder shown when there are no notifications for the active filter.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 30,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            "You're all caught up",
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
