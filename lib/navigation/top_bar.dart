import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Top app bar with logo, notification icon, alert icon, and profile icon.
class TopBar extends StatelessWidget {
  /// Creates a [TopBar].
  const TopBar({
    this.onFavoritesTap,
    this.onNotificationTap,
    this.onAlertTap,
    this.onProfileTap,
    super.key,
  });

  /// Called when the favorites icon is tapped.
  final VoidCallback? onFavoritesTap;

  /// Called when the notification icon is tapped.
  final VoidCallback? onNotificationTap;

  /// Called when the alert icon is tapped.
  final VoidCallback? onAlertTap;

  /// Called when the profile icon is tapped.
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(
              Icons.directions_transit_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'KNN',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        _IconButton(
          icon: Icons.bookmark_outline_rounded,
          onTap: onFavoritesTap,
        ),
        const SizedBox(width: 8),
        _IconButton(
          icon: Icons.notifications_outlined,
          onTap: onNotificationTap,
        ),
        const SizedBox(width: 8),
        _IconButton(
          icon: Icons.warning_amber_rounded,
          onTap: onAlertTap,
        ),
        const SizedBox(width: 8),
        _IconButton(
          icon: Icons.person_outline_rounded,
          onTap: onProfileTap,
        ),
      ],
    );
  }
}

/// Small circular icon button used in the top bar.
class _IconButton extends StatelessWidget {
  /// Creates an [_IconButton].
  const _IconButton({required this.icon, this.onTap});

  /// Icon to display.
  final IconData icon;

  /// Tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}
