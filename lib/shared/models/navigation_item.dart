import 'package:flutter/material.dart';

class NavigationItem {
  const NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

const navigationItems = <NavigationItem>[
  NavigationItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/'),
  NavigationItem(label: 'Clientes', icon: Icons.people_alt_rounded, route: '/clientes'),
  NavigationItem(label: 'Vehículos', icon: Icons.directions_car_filled_rounded, route: '/vehiculos'),
  NavigationItem(label: 'Proformas', icon: Icons.receipt_long_rounded, route: '/proformas'),
  NavigationItem(label: 'Trabajos', icon: Icons.build_rounded, route: '/trabajos'),
  NavigationItem(label: 'Contabilidad', icon: Icons.assessment_rounded, route: '/contabilidad'),
  NavigationItem(label: 'Configuración', icon: Icons.settings_rounded, route: '/configuracion'),
];
