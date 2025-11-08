import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LevelPyramidDialog extends StatelessWidget {
  final int currentLevel;

  const LevelPyramidDialog({
    super.key,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white24, width: 1),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Levels',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'You need to reach a certain level to unlock chests of that level. Higher level chests contain better rewards!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              _buildLevel(context, 5, 'Master', currentLevel >= 5),
              const SizedBox(height: 8),
              _buildLevel(context, 4, 'Expert', currentLevel >= 4),
              const SizedBox(height: 8),
              _buildLevel(context, 3, 'Advanced', currentLevel >= 3),
              const SizedBox(height: 8),
              _buildLevel(context, 2, 'Intermediate', currentLevel >= 2),
              const SizedBox(height: 8),
              _buildLevel(context, 1, 'Beginner', currentLevel >= 1),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevel(
    BuildContext context,
    int level,
    String label,
    bool isUnlocked,
  ) {
    final isCurrent = currentLevel == level;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? (isCurrent ? AppTheme.gemGreen.withOpacity(0.3) : Colors.white.withOpacity(0.1))
            : Colors.grey.withOpacity(0.1),
        border: Border.all(
          color: isCurrent
              ? AppTheme.gemGreen
              : (isUnlocked ? Colors.white24 : Colors.grey.withOpacity(0.3)),
          width: isCurrent ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/chests/level-$level.png',
            width: 64,
            height: 64,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(width: 64, height: 64);
            },
          ),
          const SizedBox(width: 12),
          Text(
            'Lv $level',
            style: TextStyle(
              color: isUnlocked ? Colors.white : Colors.grey,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: isUnlocked ? Colors.white70 : Colors.grey,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(width: 8),
            const Icon(Icons.star, color: AppTheme.gemGreen, size: 16),
          ],
        ],
      ),
    );
  }
}

