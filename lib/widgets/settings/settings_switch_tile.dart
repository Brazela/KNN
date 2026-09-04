import 'package:flutter/material.dart';

import '../../utils/constants.dart';


class SettingsSwitchTile extends StatelessWidget {
  /// Creates a [SettingsSwitchTile].
  const SettingsSwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  /// Icon shown at the start of the row.
  final IconData icon;

  /// Row label, e.g. "Dark Mode".
  final String label;

  /// Optional helper text shown under [label].
  final String? subtitle;

  /// Current toggle state.
  final bool value;

  /// Called when the user flips the switch.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }
}
