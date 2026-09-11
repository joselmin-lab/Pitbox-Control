import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/navigation_item.dart';
import '../providers/app_shell_provider.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({
    required this.currentLocation,
    this.isDrawer = false,
    super.key,
  });

  final String currentLocation;
  final bool isDrawer;

  bool _isSelected(String route) {
    if (route == '/') {
      return currentLocation == route;
    }
    return currentLocation.startsWith(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = isDrawer ? false : ref.watch(sidebarCollapsedProvider);
    final width = isCollapsed ? 92.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      color: AppColors.accent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: isCollapsed
                  ? const Center(
                      child: Icon(Icons.precision_manufacturing_rounded, color: Colors.white),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.precision_manufacturing_rounded, color: Colors.white),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                AppConstants.appName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          AppConstants.appTagline,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                      ],
                    ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                children: [
                  for (final item in navigationItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Material(
                        color: _isSelected(item.route) ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        child: ListTile(
                          leading: Icon(item.icon, color: Colors.white),
                          title: isCollapsed ? null : Text(item.label, style: const TextStyle(color: Colors.white)),
                          minLeadingWidth: 0,
                          dense: isCollapsed,
                          onTap: () {
                            context.go(item.route);
                            if (isDrawer) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!isDrawer)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(sidebarCollapsedProvider.notifier).state = !isCollapsed,
                  icon: Icon(isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded),
                  label: Text(isCollapsed ? 'Expandir' : 'Colapsar'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
