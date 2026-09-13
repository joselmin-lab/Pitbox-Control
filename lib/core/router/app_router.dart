import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/clientes/presentation/screens/cliente_detail_screen.dart';
import '../../features/clientes/presentation/screens/cliente_form_screen.dart';
import '../../features/clientes/presentation/screens/clientes_screen.dart';
import '../../features/configuracion/presentation/screens/configuracion_screen.dart';
import '../../features/configuracion/servicios/presentation/screens/paquete_servicio_detail_screen.dart';
import '../../features/configuracion/servicios/presentation/screens/paquete_servicio_form_screen.dart';
import '../../features/configuracion/servicios/presentation/screens/paquetes_servicios_screen.dart';
import '../../features/configuracion/servicios/presentation/screens/servicio_form_screen.dart';
import '../../features/configuracion/servicios/presentation/screens/servicios_screen.dart';
import '../../features/contabilidad/presentation/screens/contabilidad_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/proformas/presentation/screens/proformas_screen.dart';
import '../../features/trabajos/presentation/screens/trabajos_screen.dart';
import '../../features/vehiculos/presentation/screens/vehiculo_detail_screen.dart';
import '../../features/vehiculos/presentation/screens/vehiculo_form_screen.dart';
import '../../features/vehiculos/presentation/screens/vehiculos_screen.dart';
import '../../shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(currentLocation: state.uri.toString(), child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/clientes',
            name: 'clientes',
            builder: (context, state) => const ClientesScreen(),
            routes: [
              GoRoute(
                path: 'nuevo',
                name: 'clientes-nuevo',
                builder: (context, state) => const ClienteFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'clientes-detalle',
                builder: (context, state) => ClienteDetailScreen(clienteId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: ':id/editar',
                name: 'clientes-editar',
                builder: (context, state) => ClienteFormScreen(clienteId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/vehiculos',
            name: 'vehiculos',
            builder: (context, state) => const VehiculosScreen(),
            routes: [
              GoRoute(
                path: 'nuevo',
                name: 'vehiculos-nuevo',
                builder: (context, state) => VehiculoFormScreen(clienteId: state.uri.queryParameters['clienteId']),
              ),
              GoRoute(
                path: ':id',
                name: 'vehiculos-detalle',
                builder: (context, state) => VehiculoDetailScreen(vehiculoId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: ':id/editar',
                name: 'vehiculos-editar',
                builder: (context, state) => VehiculoFormScreen(vehiculoId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/proformas',
            name: 'proformas',
            builder: (context, state) => const ProformasScreen(),
          ),
          GoRoute(
            path: '/trabajos',
            name: 'trabajos',
            builder: (context, state) => const TrabajosScreen(),
          ),
          GoRoute(
            path: '/contabilidad',
            name: 'contabilidad',
            builder: (context, state) => const ContabilidadScreen(),
          ),
          GoRoute(
            path: '/configuracion',
            name: 'configuracion',
            builder: (context, state) => const ConfiguracionScreen(),
            routes: [
              GoRoute(
                path: 'servicios',
                name: 'configuracion-servicios',
                builder: (context, state) => const ServiciosScreen(),
                routes: [
                  GoRoute(
                    path: 'nuevo',
                    name: 'configuracion-servicios-nuevo',
                    builder: (context, state) => const ServicioFormScreen(),
                  ),
                  GoRoute(
                    path: ':id/editar',
                    name: 'configuracion-servicios-editar',
                    builder: (context, state) => ServicioFormScreen(servicioId: state.pathParameters['id']!),
                  ),
                ],
              ),
              GoRoute(
                path: 'paquetes',
                name: 'configuracion-paquetes',
                builder: (context, state) => const PaquetesServiciosScreen(),
                routes: [
                  GoRoute(
                    path: 'nuevo',
                    name: 'configuracion-paquetes-nuevo',
                    builder: (context, state) => const PaqueteServicioFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'configuracion-paquetes-detalle',
                    builder: (context, state) =>
                        PaqueteServicioDetailScreen(paqueteId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: ':id/editar',
                    name: 'configuracion-paquetes-editar',
                    builder: (context, state) =>
                        PaqueteServicioFormScreen(paqueteId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
