import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom button wrapper that matches LuckyUI design principles
class LuckyButtonWrapper extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LuckyButtonVariant variant;
  final bool isFullWidth;

  const LuckyButtonWrapper({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = LuckyButtonVariant.primary,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;
    
    if (variant == LuckyButtonVariant.outline) {
      button = OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppTheme.gemGreen),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      button = ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.gemGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

enum LuckyButtonVariant {
  primary,
  outline,
}

