import 'package:flutter/material.dart';

import '../../utils/constants.dart';

/// A single settings row that navigates elsewhere when tapped.
///
/// Used for the About section (Privacy Policy, Terms of Use, Contact Us,
/// Send Feedback) — the `SettingLink` / `TextButton` entry in the Settings
/// widget list.
class SettingsLinkTile extends StatelessWidget {
  /// Creates a [SettingsLinkTile].
  const SettingsLinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  /// Icon shown at the start of the row.
  final IconData icon;

  /// Row label, e.g. "Privacy Policy".
  final String label;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
