import 'package:flutter/material.dart';
import '../../core/config/app_constants.dart';
import '../../core/theme/app_spacing.dart';
import 'app_sidebar.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.child,
    required this.currentLocation,
    super.key,
  });

  final Widget child;
  final String currentLocation;

  static const double mobileBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < mobileBreakpoint;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.precision_manufacturing_rounded),
            SizedBox(width: AppSpacing.sm),
            Text(AppConstants.appName),
          ],
        ),
      ),
      drawer: isMobile ? Drawer(child: AppSidebar(currentLocation: currentLocation, isDrawer: true)) : null,
      body: Row(
        children: [
          if (!isMobile) AppSidebar(currentLocation: currentLocation),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
