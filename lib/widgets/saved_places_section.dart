import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';

class SavedPlacesSection extends StatelessWidget {

  const SavedPlacesSection({
    required this.onSelect,
    super.key,
  });

  final void Function(Location location, String label) onSelect;

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final home = tripProvider.home;
    final work = tripProvider.work;
    if (home == null && work == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            'SAVED PLACES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
        ),
        if (home != null)
          _SavedPlaceTile(
            icon: Icons.home_rounded,
            color: AppColors.primary,
            label: 'Home',
            address: home.address,
            onTap: () => onSelect(home, 'Home'),
          ),
        if (work != null)
          _SavedPlaceTile(
            icon: Icons.work_outline_rounded,
            color: AppColors.success,
            label: 'Work',
            address: work.address,
            onTap: () => onSelect(work, 'Work'),
          ),
        const Divider(height: 1),
      ],
    );
  }
}

class _SavedPlaceTile extends StatelessWidget {
  const _SavedPlaceTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        address ?? 'Saved location',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
