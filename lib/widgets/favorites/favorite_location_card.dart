import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../utils/constants.dart';

/// A single saved-location row on the Favorites page (e.g. Home, Work).
///
/// Shows an icon (colour-coded by [FavoriteLocation.type]), the label and
/// address, and Edit/Delete actions.
class FavoriteLocationCard extends StatelessWidget {
  /// Creates a [FavoriteLocationCard].
  const FavoriteLocationCard({
    required this.favorite,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  /// The favorite this card displays.
  final FavoriteLocation favorite;

  /// Called when the user taps the edit icon.
  final VoidCallback onEdit;

  /// Called when the user taps the delete icon.
  final VoidCallback onDelete;

  /// Icon shown for [FavoriteLocation.type].
  IconData get _icon {
    switch (favorite.type) {
      case FavoriteLocationType.home:
        return Icons.home_rounded;
      case FavoriteLocationType.work:
        return Icons.work_outline_rounded;
      case FavoriteLocationType.custom:
        return Icons.place_rounded;
    }
  }

  /// Accent colour for [FavoriteLocation.type].
  ///
  /// Matches the Home/Work colour-coding already used by the shortcut chips
  /// on the homepage (`screens/homepage.dart` `_ShortcutsRow`), so the same
  /// place reads as the same colour everywhere in the app.
  Color get _color {
    switch (favorite.type) {
      case FavoriteLocationType.home:
        return AppColors.primary;
      case FavoriteLocationType.work:
        return AppColors.success;
      case FavoriteLocationType.custom:
        return AppColors.darkSlate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: _color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  favorite.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  favorite.location.address ?? 'No address set',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _ActionIcon(
            icon: Icons.edit_outlined,
            tooltip: 'Edit ${favorite.label}',
            onTap: onEdit,
          ),
          const SizedBox(width: 6),
          _ActionIcon(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete ${favorite.label}',
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Small square icon button used for the Edit/Delete actions.
class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
