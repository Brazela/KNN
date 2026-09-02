import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Small shortcut chip for Home, Work, or recent trips.
class ShortcutChip extends StatelessWidget {
  /// Creates a [ShortcutChip].
  const ShortcutChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// Primary label.
  final String label;

  /// Secondary label.
  final String subtitle;

  /// Accent color.
  final Color color;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Long-press callback.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
