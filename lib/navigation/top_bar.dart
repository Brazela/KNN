import 'package:flutter/material.dart';

import '../utils/constants.dart';

class TopBar extends StatelessWidget {

  const TopBar({
    this.onFavoritesTap,
    this.onNearbyServicesTap,
    this.onNotificationTap,
    super.key,
  });

  final VoidCallback? onFavoritesTap;

  final VoidCallback? onNearbyServicesTap;

  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'TripCerdas',
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
          icon: Icons.explore_outlined,
          onTap: onNearbyServicesTap,
        ),
        const SizedBox(width: 8),
        _IconButton(
          icon: Icons.notifications_outlined,
          onTap: onNotificationTap,
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {

  const _IconButton({required this.icon, this.onTap});

  final IconData icon;

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
