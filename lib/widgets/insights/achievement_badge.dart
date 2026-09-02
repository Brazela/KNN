import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../utils/constants.dart';

/// A single achievement badge — coloured and filled when unlocked, greyed
/// out with a progress bar when still locked.
class AchievementBadge extends StatelessWidget {
  /// Creates an [AchievementBadge].
  const AchievementBadge({
    required this.achievement,
    required this.icon,
    super.key,
  });

  /// The achievement this badge displays.
  final Achievement achievement;

  /// Icon for this achievement (passed in rather than looked up — see the
  /// note on `IconData` in `models/achievement.dart`).
  final IconData icon;

  bool get _hasProgress =>
      achievement.progressCurrent != null && achievement.progressTarget != null;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final tint = unlocked ? AppColors.primary : AppColors.textMuted;

    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: tint),
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            achievement.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          if (_hasProgress) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (achievement.progressCurrent! / achievement.progressTarget!)
                    .clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: AppColors.background,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
