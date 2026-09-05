import 'package:flutter/material.dart';

import '../utils/constants.dart';

class LocationPermissionDialog extends StatelessWidget {

  const LocationPermissionDialog({
    this.onAllow,
    this.onSkip,
    this.title = 'We need your location',
    this.message = 'To show nearby places and transit options',
    this.allowLabel = 'Allow',
    this.showSkip = true,
    super.key,
  });

  final VoidCallback? onAllow;

  final VoidCallback? onSkip;

  final String title;

  final String message;

  final String allowLabel;

  final bool showSkip;

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onAllow,
    VoidCallback? onSkip,
    String title = 'We need your location',
    String message = 'To show nearby places and transit options',
    String allowLabel = 'Allow',
    bool showSkip = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LocationPermissionDialog(
        onAllow: onAllow,
        onSkip: onSkip,
        title: title,
        message: message,
        allowLabel: allowLabel,
        showSkip: showSkip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        if (showSkip)
          TextButton(
            onPressed: () {
              onSkip?.call();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Skip',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            onAllow?.call();
            Navigator.of(context).pop();
          },
          child: Text(
            allowLabel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
