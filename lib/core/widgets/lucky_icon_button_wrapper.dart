import 'package:flutter/material.dart';

/// Custom icon button wrapper that matches LuckyUI design principles
class LuckyIconButtonWrapper extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  const LuckyIconButtonWrapper({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color ?? Colors.white70),
      onPressed: onPressed,
    );
  }
}

