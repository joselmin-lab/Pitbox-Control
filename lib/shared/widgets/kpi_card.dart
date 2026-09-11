import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    this.highlight = false,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final background = highlight ? AppColors.primary : AppColors.surface;
    final foreground = highlight ? Colors.white : AppColors.textPrimary;
    final secondary = highlight ? Colors.white70 : AppColors.textSecondary;

    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: foreground),
                const Spacer(),
                Icon(Icons.trending_up_rounded, color: secondary),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: secondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
