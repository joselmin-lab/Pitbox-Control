import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/configuracion/taller/presentation/providers/taller_info_provider.dart';
import 'app_sidebar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    required this.child,
    required this.currentLocation,
    super.key,
  });

  final Widget child;
  final String currentLocation;

  static const double mobileBreakpoint = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < mobileBreakpoint;
    final tallerInfo = ref.watch(tallerInfoProvider).valueOrNull;
    final logoUrl = tallerInfo?.logoUrl?.trim();
    final nombreTaller = tallerInfo?.nombre.trim();
    final mostrarLogo = logoUrl != null && logoUrl.isNotEmpty;
    final titulo = (nombreTaller == null || nombreTaller.isEmpty) ? AppConstants.appName : nombreTaller;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (mostrarLogo)
              Semantics(
                label: 'Logo del taller',
                image: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    logoUrl,
                    width: 24,
                    height: 24,
                    cacheWidth: 48,
                    cacheHeight: 48,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, __, ___) => const Icon(Icons.precision_manufacturing_rounded),
                  ),
                ),
              )
            else
              const Icon(Icons.precision_manufacturing_rounded),
            const SizedBox(width: AppSpacing.sm),
            Text(titulo),
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
