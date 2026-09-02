import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../utils/constants.dart';

/// A single row on the Notifications page.
///
/// Unread notifications get a filled dot and a tinted background; tapping
/// a card marks it read via [onTap].
class NotificationCard extends StatelessWidget {
  /// Creates a [NotificationCard].
  const NotificationCard({
    required this.notification,
    required this.onTap,
    super.key,
  });

  /// The notification this card displays.
  final AppNotification notification;

  /// Called when the user taps the card (used to mark it read).
  final VoidCallback onTap;

  IconData get _icon {
    switch (notification.category) {
      case NotificationCategory.price:
        return Icons.attach_money_rounded;
      case NotificationCategory.weather:
        return Icons.cloud_outlined;
    }
  }

  Color get _color {
    switch (notification.category) {
      case NotificationCategory.price:
        return AppColors.success;
      case NotificationCategory.weather:
        return AppColors.primary;
    }
  }

  /// Formats [notification.timestamp] as a short relative time, e.g.
  /// "5m ago", "3h ago", "Yesterday".
  ///
  /// Kept local to this widget rather than added to `utils/helpers.dart`:
  /// relative-time display is specific to a notification feed, while
  /// `formatDateTime`/`formatDate` in `helpers.dart` are absolute-time
  /// formatters used elsewhere (trip history, etc.) and are left as-is.
  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _relativeTime(notification.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
